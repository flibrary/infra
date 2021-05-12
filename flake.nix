{
  description = "Basic infrastructure for FLibrary NixOS servers";

  inputs = {
    deploy-rs.url = "github:serokell/deploy-rs";
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, deploy-rs, utils, ... }:
    utils.lib.eachSystem (utils.lib.defaultSystems) (system: rec {
      apps = {
        fmt = utils.lib.mkApp {
          drv = with import nixpkgs { system = "${system}"; };
            pkgs.writeShellScriptBin "flibrary-infra-fmt" ''
              export PATH=${
                pkgs.lib.strings.makeBinPath [
                  findutils
                  nixfmt
                  shfmt
                  shellcheck
                ]
              }
              find . -type f -name '*.sh' -exec shellcheck {} +
              find . -type f -name '*.sh' -exec shfmt -w {} +
              find . -type f -name '*.nix' -exec nixfmt {} +
            '';
        };
        commit = (import ./commit.nix {
          lib = utils.lib;
          pkgs = import nixpkgs { system = "${system}"; };
        });
        # Ref back to the deploy-rs app.
        deploy = deploy-rs.apps.${system}.deploy-rs;
      };
    }) // {
      # The ISO image
      packages.x86_64-linux.img =
        self.nixosConfigurations.img.config.system.build.isoImage;

      # Reusable NixOS modules
      nixosModules = {
        base = (import ./modules/base.nix);
        vultr-hardware = (import ./hardware-cfgs/vultr-hardware.nix);
      };

      nixosConfigurations = {
        # The NixOS configuration for our machine in Silicon Valley
        flibrary-sv = nixpkgs.lib.nixosSystem {
          # Apparently this is x86_64 only
          system = "x86_64-linux";
          modules = [
            self.nixosModules.base
            self.nixosModules.vultr-hardware
            ./cfgs/flibrary-sv.nix
          ];
        };

        # A portable image used mostly for installation
        img = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
            self.nixosModules.base
            ./cfgs/img.nix
          ];
        };
      };

      # Deploy-rs
      deploy = {
        # Enable fast connection by default
        fastConnection = true;
        sshUser = "admin";

        nodes.flibrary-silicon-valley = {
          # Our server on vultr silicon valley!
          hostname = "45.32.131.167";
          profiles = {
            base = {
              # deploy the system profile as root
              user = "root";
              path = deploy-rs.lib.x86_64-linux.activate.nixos
                self.nixosConfigurations.flibrary-silicon-valley;
            };
          };
        };
      };

      # This is highly advised, and will prevent many possible mistakes
      checks = builtins.mapAttrs
        (system: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib;
    };
}

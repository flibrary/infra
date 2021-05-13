{ config, pkgs, lib, ... }:

with lib;

let cfg = config.base;
in {
  options.base = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };

    extraPackages = mkOption {
      type = with types; nullOr (listOf package);
      default = null;
      description = "Extra packages to install for the whole system.";
    };

    hostname = mkOption {
      type = types.str;
      default = "flibrary-generic";
      description = "The hostname of the system";
    };
  };
  config = mkIf cfg.enable (mkMerge [({
    networking.hostName = cfg.hostname;

    # Enable Nix Unstable and flake subcommand
    nix.package = pkgs.nixUnstable;
    nix.extraOptions = "experimental-features = nix-command flakes";

    # Enable the OpenSSH daemon.
    services.openssh = { enable = true; };

    # deploy-rs doesn't play well with wheel passwords when deploying, better to disable it.
    security.sudo.wheelNeedsPassword = false;

    # Allow unfree packages
    nixpkgs.config.allowUnfree = true;
    environment.systemPackages = with pkgs;
      [ wget coreutils-full git ]
      ++ optionals (cfg.extraPackages != null) cfg.extraPackages;

    # Open ports in the firewall.
    # networking.firewall.allowedTCPPorts = [ ... ];
    # networking.firewall.allowedUDPPorts = [ ... ];

    # GC and optimizations
    nix.optimise.automatic = true;
    nix.gc.automatic = true;
    nix.gc.options = "--delete-older-than 7d";
  })]);
}

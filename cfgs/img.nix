{ config, pkgs, ... }: {
  base = {
    enable = true;
    # Add installation script into LiveCD.
    extraPackages = [
      (pkgs.writeShellScriptBin "install-script"
        (builtins.readFile ../install.sh))
    ];
  };

  # Key(s) for SSH login during installation
  users.users.nixos.openssh.authorizedKeys.keys =
    [ (import ../keys/ssh.nix).ash ];
}

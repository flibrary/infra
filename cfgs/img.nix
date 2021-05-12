{ config, pkgs, ... }: {
  base = {
    enable = true;
    isImg = true;
    # Add installation script into LiveCD.
    extraPackages = [
      (pkgs.writeShellScriptBin "install-script"
        (builtins.readFile ../install.sh))
    ];
  };
}

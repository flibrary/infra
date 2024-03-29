{ config, lib, pkgs, ... }: {
  imports = [
    ./secrets.nix
    ./web-services.nix # User-facing services like discourse, keycloak, sails, wiki-js
    ./web-infras.nix # Web infra like nginx, v2ray, mailserver
  ];

  system.stateVersion = "21.11";

  base = {
    enable = true;
    hostname = "flibrary-sv";
  };

  time.timeZone = "America/Los_Angeles";

  # Firewall options
  networking.firewall.allowedTCPPorts = [ 80 443 ];

  # This is required to push "unsigned" nix store paths. We only allow wheel group to do so to limit the attack surface.
  nix.settings.trusted-users = [ "@wheel" ];

  users = {
    # Let users be immutable/declarative
    mutableUsers = false;
    # Note: these are only basic users, users for specific profiles/services, e.g. networking services' pseudo users are declared seperately
    # Note: for portable usages, passwords should be changed here.
    users = {
      root.hashedPassword =
        "$6$EKVU.ASDFD1ehd$HhL4g2ZSAKy7w5hOZPcrzxcd3R3axmx6Ku/xL6lvoGy1kJ1flTpxXEPNO/wxCYaxGQHt2Nt5VsY5VBmWU1dAV/";
      # A user for SSH login
      admin = {
        openssh.authorizedKeys.keys =
          [ (import ../../keys/ssh.nix).ash (import ../../keys/ssh.nix).ga ];
        hashedPassword =
          "$6$/DrCzjENUCPZ$3YWcERAWSkLiZYG8YMeyDDo6j8mJ517MZ3GmEplLeF4HVw8125.k2qEsLgNmS1IyHK7VhyaRv7Rd4azsT.nEy.";
        isNormalUser = true;
        extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
      };
    };
  };
}

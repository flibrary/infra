{ config, pkgs, ... }: {
  base = {
    enable = true;
    hostname = "flibrary-sv";
  };

  # Secrets used by this machine
  age.secrets = {
    v2ray.file = ../secrets/v2ray.age;
    sails = {
      file = ../secrets/sails.age;
      owner = "sails";
    };
    mastodon = {
      file = ../secrets/mastodon.age;
      owner = "mastodon";
    };
  };

  # Firewall options
  networking.firewall.allowedTCPPorts = [ 80 443 ];

  services.caddy = let
    cfg = {
      domain = "flibrary.info";
      reverseDstPort = 8000;
      mastodonPort = config.services.mastodon.webPort;
    };
  in {
    enable = true;
    config = ''
      ${cfg.domain} {
          reverse_proxy 127.0.0.1:${toString cfg.reverseDstPort}
          reverse_proxy /rayon localhost:30800 {
            header_up -Origin
          }
      }
      www.${cfg.domain} {
          reverse_proxy 127.0.0.1:${toString cfg.reverseDstPort}
          reverse_proxy /rayon localhost:30800 {
            header_up -Origin
          }
      }
      forum.${cfg.domain} {
          reverse_proxy 127.0.0.1:${toString cfg.mastodonPort}
      }
    '';
  };

  services.v2ray = {
    enable = true;
    configFile = config.age.secrets.v2ray.path;
  };

  # v2ray-config = {
  #   enable = true;
  #   port = 30800;
  #   path = "/rayon";
  #   clients = (import config.age.secrets.v2ray).clients;
  # };

  sails = {
    enable = true;
    configFile = config.age.secrets.sails.path;
    package = pkgs.sails;
  };

  services.mastodon = {
    enable = true;
    localDomain = "forum.flibrary.info";
    smtp = {
      createLocally = false;
      host = "smtp-mail.outlook.com";
      user = "flibrarynfls@outlook.com";
      fromAddress = "flibrarynfls@outlook.com";
      passwordFile = config.age.secrets.mastodon.path;
    };
  };

  # This is required to push "unsigned" nix store paths. We only allow wheel group to do so to limit the attack surface.
  nix.trustedUsers = [ "@wheel" ];

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
          [ (import ../keys/ssh.nix).ash (import ../keys/ssh.nix).ga ];
        hashedPassword =
          "$6$/DrCzjENUCPZ$3YWcERAWSkLiZYG8YMeyDDo6j8mJ517MZ3GmEplLeF4HVw8125.k2qEsLgNmS1IyHK7VhyaRv7Rd4azsT.nEy.";
        isNormalUser = true;
        extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
      };
    };
  };
}

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
    # NOTE: we shall create a common `s3` group to manage all users with s3 read/write access
    s3-access-key = {
      file = ../secrets/s3-access-key.age;
      owner = "mastodon";
    };
    s3-secret-key = {
      file = ../secrets/s3-secret-key.age;
      owner = "mastodon";
    };
  };

  # Firewall options
  networking.firewall.allowedTCPPorts = [ 80 443 ];

  services.caddy = let
    cfg = {
      domain = "flibrary.info";
      reverseDstPort = 8000;
      mastodonWebPort = config.services.mastodon.webPort;
      mastodonStreamingPort = config.services.mastodon.streamingPort;
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
      mastodon-assets.${cfg.domain} {
          reverse_proxy https://mastodon.ewr1.vultrobjects.com
      }
      circle.${cfg.domain} {
          @local {
            file
            not path /
          }
          @local_media {
            path_regexp /system/(.*)
          }
          @streaming {
            path /api/v1/streaming/*
          }
          @cache_control {
            path_regexp ^/(emoji|packs|/system/accounts/avatars|/system/media_attachments/files)
          }

          root * ${config.services.mastodon.package}/public/

          encode zstd gzip

          handle_errors {
            rewrite 500.html
            file_server
          }

          header {
            Strict-Transport-Security "max-age=31536000"
          }
          header /sw.js Cache-Control "public, max-age=0"
          header @cache_control Cache-Control "public, max-age=31536000, immutable"

          handle @local {
            file_server
          }

          ## If you've been migrated media from local to object storage, this navigate old URL to new one.
          # redir @local_media https://yourobjectstorage.example.com/{http.regexp.1} permanent

          reverse_proxy @streaming {
            to http://localhost:${toString cfg.mastodonStreamingPort}

            transport http {
              keepalive 5s
              keepalive_idle_conns 10
            }
          }

          reverse_proxy  {
            to http://localhost:${toString cfg.mastodonWebPort}

            header_up X-Forwarded-Port 443
            header_up X-Forwarded-Proto https

            transport http {
              keepalive 5s
              keepalive_idle_conns 10
            }
          }
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

  mastodon = {
    enable = true;
    localDomain = "circle.flibrary.info";
    enableUnixSocket = false;
    smtp = {
      createLocally = false;
      host = "smtp-mail.outlook.com";
      user = "flibrarynfls@outlook.com";
      port = 587;
      fromAddress = "FLibrary Mastodon <flibrarynfls@outlook.com>";
      passwordFile = config.age.secrets.mastodon.path;
    };
    s3 = {
      secretKeyPath = config.age.secrets.s3-secret-key.path;
      accessKeyPath = config.age.secrets.s3-access-key.path;
    };
    extraConfig = {
      SMTP_AUTH_METHOD="login";
      SMTP_OPENSSL_VERIFY_MODE="none";

      S3_ALIAS_HOST = "mastodon-assets.flibrary.info";
      S3_ENABLED="true";
      S3_BUCKET="mastodon";
      S3_PROTOCOL="https";
      S3_HOSTNAME="ewr1.vultrobjects.com";
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

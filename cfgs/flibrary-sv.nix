{ config, lib, pkgs, ... }: {
  system.stateVersion = "21.11";

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

    # keycloak database password
    keycloak-db-pass.file = ../secrets/keycloak.age;


    discourse-admin-passwd = {
      file = ../secrets/discourse-admin-passwd.age;
      owner = "discourse";
    };
    discourse-email = {
      file = ../secrets/email.age;
      owner = "discourse";
    };
    # NOTE: we shall create a common `s3` group to manage all users with s3 read/write access
    discourse-s3-access-key = {
      file = ../secrets/s3-access-key.age;
      owner = "discourse";
    };
    discourse-s3-secret-key = {
      file = ../secrets/s3-secret-key.age;
      owner = "discourse";
    };
    discourse-secret-key = {
      file = ../secrets/discourse-secret-key.age;
      owner = "discourse";
    };
  };

  # Firewall options
  networking.firewall.allowedTCPPorts = [ 80 443 ];

  services.v2ray = {
    enable = true;
    configFile = config.age.secrets.v2ray.path;
  };

  sails = {
    enable = true;
    configFile = config.age.secrets.sails.path;
    package = pkgs.sails-bin;
  };

  # SSO with keycloak
  services.keycloak = {
    enable = true;
    settings = {
      proxy = "edge";
      http-port = 8090;
      hostname = "id.flibrary.info";
      hostname-strict-backchannel = true;
    };
    initialAdminPassword = "changeme";  # change on first login
    database.passwordFile = config.age.secrets.keycloak-db-pass.path;
  };

  # Private wiki by Wiki.js
  wiki-js-patched = {
    enable = true;
    # Local access only
    settings = {
      bindIP = "127.0.0.1";
      db = {
        host = "/run/postgresql";
        db = "wiki";
        user = "wikijs";
      };
    };
  };

  services.nginx = {
    enable = true;

    clientMaxBodySize = "100m";

    recommendedTlsSettings = true;
    recommendedOptimisation = true;
    recommendedGzipSettings = true;
    recommendedProxySettings = true;

    virtualHosts."flibrary.info" = {
      enableACME = true;
      forceSSL = true;
      # sails
      locations."/".proxyPass = "http://127.0.0.1:8000";
      # v2ray
      locations."/rayon" = {
        proxyWebsockets = true;
        proxyPass = "http://127.0.0.1:30800";
      };
      serverAliases = [ "www.flibrary.info" ];
    };

    virtualHosts."id.flibrary.info" = {
      enableACME = true;
      forceSSL = true;
      # wiki
      locations."/".proxyPass = "http://127.0.0.1:8090";
    };

    virtualHosts."wiki.flibrary.info" = {
      enableACME = true;
      forceSSL = true;
      # wiki
      locations."/".proxyPass = "http://127.0.0.1:3000";
    };
  };

  services.discourse = {
    enable = true;
    plugins = with config.services.discourse.package.plugins; [
      discourse-solved
      discourse-math
    ];
    hostname = "circle.flibrary.info";
    mail = {
      outgoing = {
        username = "circle@flibrary.info";
        serverAddress = "mail.flibrary.info";
        passwordFile = config.age.secrets.discourse-email.path;
        opensslVerifyMode = "none";
        authentication = "login";
        port = 587;
      };
      contactEmailAddress = "admin@flibrary.info";
      notificationEmailAddress = "circle@flibrary.info";
    };
    admin = {
      username = "admin";
      email = "admin@flibrary.info";
      fullName = "FLibrary Circle Admin";
      passwordFile = config.age.secrets.discourse-admin-passwd.path;
    };
    secretKeyBaseFile = config.age.secrets.discourse-secret-key.path;
    siteSettings = {
      required = {
        title = "FLibrary Circle";
        short_site_description =
          "A dynamic and informative platform made for international students";
      };
      developer.bypass_wizard_check = false;

      security.force_https = true;
      files = let asset_bucket = "flibrarycircle";
      in {
        enable_s3_uploads = true;
        s3_access_key_id._secret =
          config.age.secrets.discourse-s3-access-key.path;
        s3_secret_access_key._secret =
          config.age.secrets.discourse-s3-secret-key.path;
        s3_upload_bucket = asset_bucket;
        s3_endpoint = "https://s3.us-west-004.backblazeb2.com";
        s3_cdn_url = "https://cdn.flibrary.info/file/${asset_bucket}";

        # We are using object storage, there is no risk on allowing this.
        authorized_extensions = "*";
      };
      backups.s3_backup_bucket = "flibrarycirclebackup";

      users = { allow_anonymous_posting = true; };
      # Copied from https://github.com/discourse/discourse/blob/main/config/site_settings.yml to accomodate zh_CN posts
      posting = {
        body_min_entropy = 3;
        min_topic_title_length = 6;
      };
      search.min_search_term_length = 1;
      uncategoriezed.slug_generation_method = "none";
    };
  };

  mailserver = {
    enable = true;
    fqdn = "mail.flibrary.info";
    domains = [ "flibrary.info" ];

    # A list of all login accounts. To create the password hashes, use
    # mkpasswd -m sha-512
    loginAccounts = {
      # Used by sails
      "sails@flibrary.info" = {
        hashedPassword =
          "$6$ZGbdd01cFfnno19T$o2n4aaiyERPY8aML2xzVlmVpX77A5ktLFOAuuNdp878OkHb8fz2hyLl.uT8YD0Ueq.sb6wFl8i8m554DozUHc1";
        sendOnly = true;
      };
      # The email address used by FLibrary Circle
      "circle@flibrary.info" = {
        hashedPassword =
          "$6$sHjgQ2IynYkQXd4d$Cmm9k7sY2TZOkLVsKLkdVDxybq7S3kJoEBZuz.8iinuksochdt6Y9hU7OFSsFPPKT0Mw5gb648YVy/QtFMxh40";
        sendOnly = true;
      };
      # Used by me
      "harryying@flibrary.info" = {
        hashedPassword =
          "$6$MNxXCDu93K.Nvd2X$pO8OYYlU2p2rPChTVJ8bH3uKQWaXM3ZTJ6eLyW5Ey/Tf6WtIXWy4VeTVxaKyJlGLen6zygfe3o78R4E2DN8m./";
        aliases = [ "admin@flibrary.info" "harry@flibrary.info" ];
      };
      "wiki@flibrary.info" = {
        hashedPassword = "$6$fmSk1cH2O9AYe9OW$iBnOJE1MuMQL2d8G9Yo0H74AkhArvy0ykSZS349yWJqxGAd6Eb1sKIVzVGS.oPalr3SccxeJgUqG0y.ImlCE40";
        sendOnly = true;
      };
      "mick@flibrary.info" = {
        hashedPassword = "$6$kW2NcqUajtH7tOXT$ApvNww15pfmG5SA15CkGzydhjXRuVvuYO2CujiLrTIxFLe..k2fluV2RUgUAOq0DNjtx7WEcr6hy1a0vHWnlz0";
      };
    };

    # Use Let's Encrypt certificates. Note that this needs to set up a stripped
    # down nginx and opens port 80.
    certificateScheme = 3;
  };

  security.acme = {
    defaults.email = "lexugeyky@outlook.com";
    acceptTerms = true;
  };

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
          [ (import ../keys/ssh.nix).ash (import ../keys/ssh.nix).ga ];
        hashedPassword =
          "$6$/DrCzjENUCPZ$3YWcERAWSkLiZYG8YMeyDDo6j8mJ517MZ3GmEplLeF4HVw8125.k2qEsLgNmS1IyHK7VhyaRv7Rd4azsT.nEy.";
        isNormalUser = true;
        extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
      };
    };
  };
}

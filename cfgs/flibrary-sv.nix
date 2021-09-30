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
    package = pkgs.sails;
  };

  services.nginx = {
    enable = true;

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
  };

  services.discourse = {
    enable = true;
    plugins = with config.services.discourse.package.plugins;
      [ discourse-data-explorer ];
    hostname = "circle.flibrary.info";
    mail = {
      outgoing = {
        username = "flibrarynfls@outlook.com";
        serverAddress = "smtp-mail.outlook.com";
        passwordFile = config.age.secrets.discourse-email.path;
        opensslVerifyMode = "none";
        authentication = "login";
        port = 587;
      };
      contactEmailAddress = "flibrarynfls@outlook.com";
      notificationEmailAddress = "flibrarynfls@outlook.com";
    };
    admin = {
      username = "admin";
      email = "flibrarynfls@outlook.com";
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
      files = {
        enable_s3_uploads = true;
        s3_access_key_id._secret =
          config.age.secrets.discourse-s3-access-key.path;
        s3_secret_access_key._secret =
          config.age.secrets.discourse-s3-secret-key.path;
        s3_upload_bucket = "flibrarycircle";
        s3_endpoint = "https://ewr1.vultrobjects.com";

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

  security.acme = {
    email = "lexugeyky@outlook.com";
    acceptTerms = true;
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

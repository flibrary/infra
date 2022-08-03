{ config, lib, pkgs, ... }: {
  sails = {
    enable = true;
    configFile = config.age.secrets.sails.path;
    package = pkgs.sails-bin;
    after = [ "keycloak.service" ];
    wants = [ "keycloak.service" ];
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
    themes = { keywind = pkgs.keywind-theme; };
    initialAdminPassword = "changeme"; # change on first login
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

  systemd.services.discourse.environment = {
    # Too much unicorn workers consuming memory
    UNICORN_WORKERS = "2";
  };
  services.discourse = {
    enable = true;
    plugins = with config.services.discourse.package.plugins; [
      discourse-solved
      discourse-math
      discourse-openid-connect
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
}

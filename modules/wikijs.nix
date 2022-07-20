{ lib, pkgs, config, ... }:

with lib;

let
  cfg = config.wiki-js-patched;

  format = pkgs.formats.json { };

  configFile = format.generate "wiki-js.yml" cfg.settings;
in {
  options.wiki-js-patched = {
    enable = mkEnableOption "wiki-js";

    environmentFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      example = "/root/wiki-js.env";
      description = ''
        Environment fiel to inject e.g. secrets into the configuration.
      '';
    };

    stateDirectoryName = mkOption {
      default = "wiki-js";
      type = types.str;
      description = ''
        Name of the directory in <filename>/var/lib</filename>.
      '';
    };

    settings = mkOption {
      default = { };
      type = types.submodule {
        freeformType = format.type;
        options = {
          port = mkOption {
            type = types.port;
            default = 3000;
            description = ''
              TCP port the process should listen to.
            '';
          };

          bindIP = mkOption {
            default = "0.0.0.0";
            type = types.str;
            description = ''
              IPs the service should listen to.
            '';
          };

          db = {
            type = mkOption {
              default = "postgres";
              type = types.enum [ "postgres" "mysql" "mariadb" "mssql" ];
              description = ''
                Database driver to use for persistence. Please note that <literal>sqlite</literal>
                is currently not supported as the build process for it is currently not implemented
                in <package>pkgs.wiki-js</package> and it's not recommended by upstream for
                production use.
              '';
            };
            host = mkOption {
              type = types.str;
              example = "/run/postgresql";
              description = ''
                Hostname or socket-path to connect to.
              '';
            };
            db = mkOption {
              default = "wiki";
              type = types.str;
              description = ''
                Name of the database to use.
              '';
            };
          };

          logLevel = mkOption {
            default = "info";
            type =
              types.enum [ "error" "warn" "info" "verbose" "debug" "silly" ];
            description = ''
              Define how much detail is supposed to be logged at runtime.
            '';
          };

          offline = mkEnableOption "offline mode" // {
            description = ''
              Disable latest file updates and enable
              <link xlink:href="https://docs.requarks.io/install/sideload">sideloading</link>.
            '';
          };
        };
      };
      description = ''
        Settings to configure <package>wiki-js</package>. This directly
        corresponds to <link xlink:href="https://docs.requarks.io/install/config">the upstream
        configuration options</link>.
        Secrets can be injected via the environment by
        <itemizedlist>
          <listitem><para>specifying <xref linkend="opt-services.wiki-js.environmentFile" />
          to contain secrets</para></listitem>
          <listitem><para>and setting sensitive values to <literal>$(ENVIRONMENT_VAR)</literal>
          with this value defined in the environment-file.</para></listitem>
        </itemizedlist>
      '';
    };
  };

  config = mkIf cfg.enable {
    services.wiki-js.settings.dataPath = "/var/lib/${cfg.stateDirectoryName}";
    systemd.services.wiki-js = {
      description = "A modern and powerful wiki app built on Node.js";
      documentation = [ "https://docs.requarks.io/" ];
      wantedBy = [ "multi-user.target" ];

      path = with pkgs; [ coreutils ];
      preStart = ''
        ln -sf ${configFile} /var/lib/${cfg.stateDirectoryName}/config.yml
        ln -sf ${pkgs.wiki-js}/server /var/lib/${cfg.stateDirectoryName}
        ln -sf ${pkgs.wiki-js}/assets /var/lib/${cfg.stateDirectoryName}
        ln -sf ${pkgs.wiki-js}/package.json /var/lib/${cfg.stateDirectoryName}/package.json
      '';

      serviceConfig = {
        EnvironmentFile =
          mkIf (cfg.environmentFile != null) cfg.environmentFile;
        StateDirectory = cfg.stateDirectoryName;
        WorkingDirectory = "/var/lib/${cfg.stateDirectoryName}";
        User = "wikijs";
        Group = "wikijs";
        ExecStart = "${pkgs.nodejs}/bin/node ${pkgs.wiki-js}/server";

        # RemoveIPC = true;
        PrivateTmp = true;
        # NoNewPrivileges = true;
        # RestrictSUIDSGID = true;
        # ProtectSystem = "strict";
        # ProtectHome = "read-only";
      };
    };

    # Create postgres user for wiki-js
    services.postgresql.ensureUsers = [{ name = "wikijs"; }];

    # Create postgres db for wiki-js
    systemd.services.wikijs-postgresql = let
      pgsql = config.services.postgresql;
      dbname = cfg.settings.db.db;
      dbuser = cfg.settings.db.user;
    in {
      after = [ "postgresql.service" ];
      bindsTo = [ "postgresql.service" ];
      wantedBy = [ "wiki-js.service" ];
      partOf = [ "wiki-js.service" ];
      path = [ pgsql.package ];
      script = ''
        set -o errexit -o pipefail -o nounset -o errtrace
        shopt -s inherit_errexit
        psql -tAc "SELECT 1 FROM pg_database WHERE datname = '${dbname}'" | grep -q 1 || psql -tAc 'CREATE DATABASE "${dbname}" OWNER "${dbuser}"'
        psql '${dbname}' -tAc "CREATE EXTENSION IF NOT EXISTS pg_trgm"
      '';

      serviceConfig = {
        User = pgsql.superUser;
        Type = "oneshot";
        RemainAfterExit = true;
      };
    };

    users.users = {
      wikijs = {
        group = "wikijs";
        isSystemUser = true;
      };
    };
    users.groups.wikijs = { };
  };

  meta.maintainers = with maintainers; [ ma27 ];
}

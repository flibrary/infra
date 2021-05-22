{ config, pkgs, lib, ... }:

with lib;

let cfg = config.webserver;
in {
  options.webserver = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };

    domain = mkOption {
      type = types.str;
      description = "The domain of the server";
    };

    reverseDstPort = mkOption {
      type = types.port;
      description = "Local port that the actual server is listening on";
    };
  };
  config = mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [ 80 443 ];

    services.caddy = {
      enable = true;
      config = ''
                ${cfg.domain} {
                  reverse_proxy 127.0.0.1:${toString cfg.reverseDstPort}
        	      }
                www.${cfg.domain} {
                  reverse_proxy 127.0.0.1:${toString cfg.reverseDstPort}
                }
              '';
    };
  };
}

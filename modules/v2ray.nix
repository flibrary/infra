{ config, pkgs, lib, ... }:

with lib;

let cfg = config.v2ray-config;
in {
  options.v2ray-config = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };

    clients = mkOption {
      type = with types; listOf (attrsOf anything);
      description = "clients";
    };

    path = mkOption {
      type = types.path;
      description = "webserver path where v2ray is listening on";
    };

    port = mkOption {
      type = types.port;
      description = "Local port that the v2ray server listens on";
    };
  };
  config = mkIf cfg.enable {
    services.v2ray = {
      enable = true;
      config = {
        inbounds = [{
          port = cfg.port;
          listen = "127.0.0.1";
          protocol = "vmess";
          settings = { clients = cfg.clients; };
          streamSettings = {
            network = "ws";
            wsSettings = { path = cfg.path; };
          };
        }];
        outbounds = [{
          protocol = "freedom";
          settings = { };
        }];
      };
    };
  };
}

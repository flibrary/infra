{ config, pkgs, lib, ... }: {
  age.secrets = {
    v2ray.file = ../secrets/v2ray.age;
    sails = {
      file = ../secrets/sails.age;
      owner = "sails";
    };
  };
}

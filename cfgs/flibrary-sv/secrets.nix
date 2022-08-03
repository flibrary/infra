{ config, lib, pkgs, ... }: {
  # Secrets used by this machine
  age.secrets = {
    v2ray.file = ../../secrets/v2ray.age;
    sails = {
      file = ../../secrets/sails.age;
      owner = "sails";
    };

    # keycloak database password
    keycloak-db-pass.file = ../../secrets/keycloak.age;

    discourse-admin-passwd = {
      file = ../../secrets/discourse-admin-passwd.age;
      owner = "discourse";
    };
    discourse-email = {
      file = ../../secrets/email.age;
      owner = "discourse";
    };
    # NOTE: we shall create a common `s3` group to manage all users with s3 read/write access
    discourse-s3-access-key = {
      file = ../../secrets/s3-access-key.age;
      owner = "discourse";
    };
    discourse-s3-secret-key = {
      file = ../../secrets/s3-secret-key.age;
      owner = "discourse";
    };
    discourse-secret-key = {
      file = ../../secrets/discourse-secret-key.age;
      owner = "discourse";
    };
  };
}

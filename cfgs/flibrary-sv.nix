{ config, pkgs, ... }: {
  base = {
    enable = true;
    hostname = "flibrary-sv";
  };

  webserver = {
    enable = true;
    domain = "flibrary.info";
    reverseDstPort = 8000;
  };

  v2ray-config = {
    enable = true;
    port = 30800;
    path = "/rayon";
    clients = (import ../keys/v2ray.nix).clients;
  };

  sails = {
    enable = true;
    config = {
      default = {
        databases.flibrary.url = "/var/lib/sails/db.sqlite";
        # FIXME: this is not considered secure!
        secret_key = "xpZXPM7lHtsDMVDdAAszsnmX+RxOcnosZksSvE4oPs4=";
      };
    };
    package = pkgs.sails;
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
          "$6$2XzDWOUx0/3eCx$EjIljN0bEKUW7OJMUM2RffWxvLPUC2FhMzy60Ogfy.i94vj4QNTuVcl3tV49g5z9KhNP/iTPcyncC5ndhDT3P0";
        isNormalUser = true;
        extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
      };
    };
  };
}

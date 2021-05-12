{ config, pkgs, ... }: {
  base.enable = true;

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
        hashedPassword =
          "$6$2XzDWOUx0/3eCx$EjIljN0bEKUW7OJMUM2RffWxvLPUC2FhMzy60Ogfy.i94vj4QNTuVcl3tV49g5z9KhNP/iTPcyncC5ndhDT3P0";
        isNormalUser = true;
        shell = pkgs.zsh;
        extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
      };
    };
  };
}

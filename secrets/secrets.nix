let ssh = (import ../keys/ssh.nix);
in {
  "v2ray.age".publicKeys = [ ssh.servers.flibrary-sv ssh.ash ];
  "sails.age".publicKeys = [ ssh.servers.flibrary-sv ssh.ash ];
}

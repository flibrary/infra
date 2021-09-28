let ssh = (import ../keys/ssh.nix);
in {
  "v2ray.age".publicKeys = [ ssh.servers.flibrary-sv ssh.ash ];
  "v2ray-dns-camo.age".publicKeys = [ ssh.servers.flibrary-shanghai ssh.ash ];
  "sails.age".publicKeys = [ ssh.servers.flibrary-sv ssh.ash ];
  "mastodon.age".publicKeys = [ ssh.servers.flibrary-sv ssh.ash ];
}

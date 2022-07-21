let ssh = (import ../keys/ssh.nix);
in {
  "v2ray.age".publicKeys = [ ssh.servers.flibrary-sv ssh.ash ];
  "keycloak.age".publicKeys = [ ssh.servers.flibrary-sv ssh.ash ];
  "sails.age".publicKeys = [ ssh.servers.flibrary-sv ssh.ash ];
  "email.age".publicKeys = [ ssh.servers.flibrary-sv ssh.ash ];
  "s3-access-key.age".publicKeys = [ ssh.servers.flibrary-sv ssh.ash ];
  "s3-secret-key.age".publicKeys = [ ssh.servers.flibrary-sv ssh.ash ];
  "discourse-secret-key.age".publicKeys = [ ssh.servers.flibrary-sv ssh.ash ];
  "discourse-admin-passwd.age".publicKeys = [ ssh.servers.flibrary-sv ssh.ash ];
}

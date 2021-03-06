{
  # My personal SSH Ed25519 public key
  ash =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMmrVSVSR7C4KfH78KTtdJ7Ids7+1hS0xPRAl0D83YB+ ash@x1c7";
  # SSH Ed25519 public key used by GitHub Action for continuous deployment
  ga =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPp91QcPA9sdTZ0aokP+Iy9oaydCtDl5GWLNODrEDmVQ ash@x1c7";

  servers = {
    # FLibrary SV Server pub key used for agenix encryption. If server changes, this should be changed as well.
    flibrary-sv =
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH644x5o56908R+LCQPpTOiBm7Oqp1ELk4rT3Jj1jkTD";
  };
}

{ lib, stdenv, fetchFromGitHub }:

stdenv.mkDerivation rec {
  pname = "keywind-thme";
  version = "git";

  src = fetchFromGitHub {
    owner = "lukin";
    repo = "keywind";
    rev = "224d73742ed4176920fb0c1e61f16752f6c1064c";
    sha256 = "sha256-VvpaR1bVJdjZAee05eVqWBiifWB34YYfwD9pnLVqm3M=";
    # owner = "flibrary";
    # repo = "keywind";
    # rev = "32093b06987a6e44a53ac2bf7301e448a52729ee";
    # sha256 = "sha256-fhjRW1qgqwfM5Yr73HJXLh1ZESIy1epKVFFlcbkUKsQ=";
  };

  installPhase = ''
    mkdir $out
    cp -r ./theme/keywind/* $out
  '';
}

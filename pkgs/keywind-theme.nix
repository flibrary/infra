{ lib, stdenv, fetchFromGitHub }:

stdenv.mkDerivation rec {
  pname = "keywind-thme";
  version = "git";

  src = fetchFromGitHub {
    owner = "lukin";
    repo = "keywind";
    rev = "224d73742ed4176920fb0c1e61f16752f6c1064c";
    sha256 = lib.fakeSha256;
  };

  installPhase = ''
    mkdir $out
    cp -r ./theme/keywind/* $out
  '';
}

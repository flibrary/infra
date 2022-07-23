{ lib, stdenv, fetchFromGitHub }:

stdenv.mkDerivation rec {
  pname = "keywind-thme";
  version = "git";

  src = fetchFromGitHub {
    owner = "lukin";
    repo = "keywind";
    rev = "224d73742ed4176920fb0c1e61f16752f6c1064c";
    sha256 = "sha256-VvpaR1bVJdjZAee05eVqWBiifWB34YYfwD9pnLVqm3M=";
  };

  installPhase = ''
    mkdir $out
    cp -r ./theme/keywind/* $out
  '';
}

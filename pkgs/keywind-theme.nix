{ lib, stdenv, fetchFromGitHub }:

stdenv.mkDerivation rec {
  pname = "keywind-theme";
  version = "git";

  src = fetchFromGitHub {
    # owner = "lukin";
    # repo = "keywind";
    # rev = "224d73742ed4176920fb0c1e61f16752f6c1064c";
    # sha256 = "sha256-VvpaR1bVJdjZAee05eVqWBiifWB34YYfwD9pnLVqm3M=";
    owner = "flibrary";
    repo = "keywind";
    rev = "4b05a9b7c36876e65e69f767acd235fdb218f978";
    sha256 = "sha256-zjRdKPnomvQiGDK+i+q/p8eeOtZkOMurnvp6jWXCPAs=";
  };

  installPhase = ''
    mkdir $out
    cp -r ./theme/keywind/* $out
  '';
}

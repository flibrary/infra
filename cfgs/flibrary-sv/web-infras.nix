{ config, lib, pkgs, ... }: {
  services.v2ray = {
    enable = true;
    configFile = config.age.secrets.v2ray.path;
  };

  services.nginx = {
    enable = true;

    clientMaxBodySize = "100M";

    recommendedTlsSettings = true;
    recommendedOptimisation = true;
    recommendedGzipSettings = true;
    recommendedProxySettings = true;

    virtualHosts."flibrary.info" = {
      enableACME = true;
      forceSSL = true;
      # sails
      locations."/".proxyPass = "http://127.0.0.1:8000";
      # v2ray
      locations."/rayon" = {
        proxyWebsockets = true;
        proxyPass = "http://127.0.0.1:30800";
      };
      serverAliases = [ "www.flibrary.info" ];
    };

    virtualHosts."id.flibrary.info" = {
      enableACME = true;
      forceSSL = true;
      # wiki
      locations."/".proxyPass = "http://127.0.0.1:8090";
    };

    virtualHosts."wiki.flibrary.info" = {
      enableACME = true;
      forceSSL = true;
      # wiki
      locations."/".proxyPass = "http://127.0.0.1:3000";
    };
  };

  mailserver = {
    enable = true;
    fqdn = "mail.flibrary.info";
    domains = [ "flibrary.info" ];

    # A list of all login accounts. To create the password hashes, use
    # mkpasswd -m sha-512
    loginAccounts = {
      # Used by sails
      "sails@flibrary.info" = {
        hashedPassword =
          "$6$ZGbdd01cFfnno19T$o2n4aaiyERPY8aML2xzVlmVpX77A5ktLFOAuuNdp878OkHb8fz2hyLl.uT8YD0Ueq.sb6wFl8i8m554DozUHc1";
        sendOnly = true;
      };
      # The email address used by FLibrary Circle
      "circle@flibrary.info" = {
        hashedPassword =
          "$6$sHjgQ2IynYkQXd4d$Cmm9k7sY2TZOkLVsKLkdVDxybq7S3kJoEBZuz.8iinuksochdt6Y9hU7OFSsFPPKT0Mw5gb648YVy/QtFMxh40";
        sendOnly = true;
      };
      # Used by FLibrary Wiki
      "wiki@flibrary.info" = {
        hashedPassword =
          "$6$fmSk1cH2O9AYe9OW$iBnOJE1MuMQL2d8G9Yo0H74AkhArvy0ykSZS349yWJqxGAd6Eb1sKIVzVGS.oPalr3SccxeJgUqG0y.ImlCE40";
        sendOnly = true;
      };
      # Used by FLibrary ID service
      "id@flibrary.info" = {
        hashedPassword =
          "$6$/avr1mGKZaCiktbB$BuwOJfantz9SD2bvhJ/QRUktpJ5D2jITn/4YMc47neVegkp7mUDEufoAer2xfPRDdWsX9cyqTsAsfZSqgSIj70";
        sendOnly = true;
      };
      # Used by me
      "harryying@flibrary.info" = {
        hashedPassword =
          "$6$MNxXCDu93K.Nvd2X$pO8OYYlU2p2rPChTVJ8bH3uKQWaXM3ZTJ6eLyW5Ey/Tf6WtIXWy4VeTVxaKyJlGLen6zygfe3o78R4E2DN8m./";
        aliases =
          [ "admin@flibrary.info" "harry@flibrary.info" "bd@flibrary.info" ];
      };
      "mick@flibrary.info" = {
        hashedPassword =
          "$6$kW2NcqUajtH7tOXT$ApvNww15pfmG5SA15CkGzydhjXRuVvuYO2CujiLrTIxFLe..k2fluV2RUgUAOq0DNjtx7WEcr6hy1a0vHWnlz0";
      };
    };

    # Use Let's Encrypt certificates. Note that this needs to set up a stripped
    # down nginx and opens port 80.
    certificateScheme = 3;
  };

  security.acme = {
    defaults.email = "lexugeyky@outlook.com";
    acceptTerms = true;
  };
}

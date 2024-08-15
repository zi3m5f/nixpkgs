{ lib
, buildGoModule
, callPackage
, fetchFromGitHub
, nix-update-script
, ...
}:
let
  pname = "ente-cli";
  version = "0.1.16";

  mainProgram = pname;

in
buildGoModule {
  inherit pname version;

  src = (fetchFromGitHub {
    owner = "ente-io";
    repo = "ente";
    rev = "cli-v${version}";
    hash = "sha256-h3TmhUWCZrpctNU6hUembhdcElqdl9ujUdkbg4MZD9s=";
    fetchSubmodules = false;
    sparseCheckout = [ "cli" ];
  }).overrideAttrs (_: {
    postFetch = ''
      # make 'cli' the new root dir
      cd $out
      rm LICENSE *.*
      mv cli/* .
      mv cli/.git* .
      rmdir cli
    '';
  });

  vendorHash = "sha256-Gg1mifMVt6Ma8yQ/t0R5nf6NXbzLZBpuZrYsW48p0mw=";

  postInstall = ''
    mv $out/bin/{cli,${mainProgram}}
  '';

  passthru = {
    tests = callPackage ./tests.nix { };
    updateScript = nix-update-script {
      extraArgs = [ "--version-regex" "cli-(.+)" ];
    };
  };

  meta = {
    inherit mainProgram;
    homepage = "https://github.com/ente-io/ente/cli";
    description = "CLI client for downloading your data from Ente.";
    longDescription = ''
      The Ente CLI is a Command Line Utility for exporting data from Ente. It also does a few more things, for example, you can use it to decrypting the export from Ente Auth.
    '';
    license = lib.licenses.agpl3Only;
    maintainers = [ lib.maintainers.zi3m5f ];
    platforms = [
      "aarch64-linux"
      "armv7a-linux"
      "i686-linux"
      "x86_64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
      "i686-windows"
      "x86_64-windows"
    ];
  };
}

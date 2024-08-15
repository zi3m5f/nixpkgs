{ lib
, ente-cli
, mktemp
, runCommand
, ...
}:

{
  simple = runCommand "ente-cli-test-simple" { } ''
    # fix: "mkdir /homeless-shelter: permission denied"
    export ENTE_CLI_CONFIG_PATH=$(${mktemp}/bin/mktemp -d)

    # ente-cli needs dbus and a secret service for startup
    # so just test for the correct error msg in this case
    set +o pipefail
    ${lib.getExe ente-cli} \
      |& grep "error getting password from keyring:" \
      && touch $out
  '';
}

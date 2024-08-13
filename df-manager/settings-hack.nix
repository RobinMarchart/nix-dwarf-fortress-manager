{
  lib,
  runCommand,
  writeText,

  makeWrapper,

  dfhack,
  dwarf-fortress-unwrapped,

  extraNicks ? [ ],
  defaultNicks ? true,
  dfhackInit ? "",
  onLoadInit ? "",
  onMapLoadInit ? "",
  onMapUnloadInit ? "",
  onUnloadInit ? "",
}:

lib.throwIf (dfhack.dfVersion != dwarf-fortress-unwrapped.version)
  "dwarf-fortress: dfhack and dwarf fortress have incopatible versions"
  (
    let
      options = {
        inherit
          dfhackInit
          onLoadInit
          onMapLoadInit
          onMapUnloadInit
          onUnloadInit
          ;
      };
      extraNicksFile = writeText "extraNicks" (
        "\n# nicks configured with df-manager" + lib.strings.concatMapStrings (nick: "\n${nick}") extraNicks
      );
    in
    runCommand "df-manager-settings-hack" { nativeBuildInputs = [ makeWrapper ]; } (
      ''
        mkdir -p $out/hack
        mkdir -p $out/dfhack-config/init

        # Patch the MD5
        orig_md5=$(< "${dwarf-fortress-unwrapped}/hash.md5.orig")
        patched_md5=$(< "${dwarf-fortress-unwrapped}/hash.md5")
        input_file="${dfhack}/hack/symbols.xml"
        output_file="$out/hack/symbols.xml"

        echo "[DFHack Wrapper] Fixing Dwarf Fortress MD5:"
        echo "  Input:   $input_file"
        echo "  Search:  $orig_md5"
        echo "  Output:  $output_file"
        echo "  Replace: $patched_md5"

        substitute "$input_file" "$output_file" --replace-fail "$orig_md5" "$patched_md5"

        echo linking default dfhack config
        ln -s "${dfhack}/dfhack-config/default/dfstatus.lua" "$out/dfhack-config/dfstatus.lua"
        ln -s "${dfhack}/dfhack-config/default/dwarfmonitor.json" "$out/dfhack-config/dwarfmonitor.json"
        ln -s "${dfhack}/dfhack-config/default/script-paths.txt" "$out/dfhack-config/script-paths.txt"
        ln -s "${dfhack}/dfhack-config/default/quickfort" "$out/dfhack-config/quickfort"
      ''
      + lib.optionalString (defaultNicks && extraNicks != []) ''

        echo writing combined nickname file
        cat "${dfhack}/dfhack-config/default/autonick.txt" "${extraNicksFile}" > "$out/dfhack-config/autonick.txt"
      ''
      + lib.optionalString (defaultNicks && extraNicks == []) ''

        echo linking default nickname file
        ln -s "${dfhack}/dfhack-config/default/autonick.txt" "$out/dfhack-config/autonick.txt"
      ''
      + lib.optionalString (!defaultNicks) ''

        echo linking created nickname file
        ln -s "${extraNicksFile}"  "$out/dfhack-config/autonick.txt"
      ''
      +
        lib.strings.concatMapStrings
          (
            init:
            let
              var = "${init}Init";
              initFile = writeText "dfhack-${var}" options.${var};
            in
            ''

              echo linking ${init}.init
              ln -s "${dfhack}/dfhack-config/default/init/default.${init}.init" "$out/dfhack-config/init/default.${init}.init"
              ln -s "${initFile}" "$out/dfhack-config/init/${init}.init"
            ''
          )
          [
            "dfhack"
            "onLoad"
            "onMapLoad"
            "onMapUnload"
            "onUnload"
          ]

    )
  )

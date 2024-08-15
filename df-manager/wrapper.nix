{
  lib,
  coreutils,
  dwarf-fortress,
  writeShellScriptBin,
  settingsPkg,
  settingsHackPkg,
  environmentPkg,
  ptracerPkg,
  enableDFHack ? false,
  enableTextMode ? false,
  enableTWBT ? false,
  enableTherapist ? false,
  enableTruetype ? null,
  enableFPS ? false,
  enableSound ? true,
  # An attribute set of settings to override in data/init/*.txt.
  # For example, `init.FOO = true;` is translated to `[FOO:YES]` in init.txt
  dfSettings ? { },
  saveLocation ? "/tmp/df-save",
  modsList ? [ ],
  extraPackages ? [ ],
  suffix ? "",
  extraNicks ? [ ],
  defaultNicks ? true,
  dfhackInit ? "",
  onLoadInit ? "",
  onMapLoadInit ? "",
  onMapUnloadInit ? "",
  onUnloadInit ? "",
}:
let
  newDf = dwarf-fortress.dwarf-fortress.baseVersion >= 50;
  settings = settingsPkg.override {
    dwarf-fortress-unwrapped = dwarf-fortress.dwarf-fortress;
    dfhack = dwarf-fortress.dfhack;
    twbt = dwarf-fortress.twbt;
    inherit
      enableDFHack
      enableTextMode
      enableTWBT
      enableTruetype
      enableFPS
      enableSound
      dfSettings
      ;
  };
  settingsHack = settingsHackPkg.override {
    dwarf-fortress-unwrapped = dwarf-fortress.dwarf-fortress;
    dfhack = dwarf-fortress.dfhack;
    inherit
      extraNicks
      defaultNicks
      dfhackInit
      onLoadInit
      onMapLoadInit
      onMapUnloadInit
      onUnloadInit
      ;
  };

  environment = environmentPkg.override {
    dwarf-fortress-unwrapped = dwarf-fortress.dwarf-fortress;
    dfhack = dwarf-fortress.dfhack;
    twbt = dwarf-fortress.twbt;
    settingsPkg = settings;
    settingsHackPkg = settingsHack;
    inherit
      enableDFHack
      enableTWBT
      saveLocation
      modsList
      extraPackages
      ;
  };
  df-base-script =
    ''
      set -e
      echo game directory: '${environment}'
      export NIXPKGS_DF_HOME=${environment}
      ${coreutils}/bin/mkdir -p "${saveLocation}/save"
      ${coreutils}/bin/mkdir -p "${saveLocation}/data/save"
    ''
    + lib.optionalString (!newDf) ''

      ${coreutils}/bin/touch "${saveLocation}/stderr.log"
      ${coreutils}/bin/touch "${saveLocation}/gamelog.txt"
      ${coreutils}/bin/touch "${saveLocation}/strace.log"
      ${coreutils}/bin/cp "${dwarf-fortress.dwarf-fortress}/data/index" "${saveLocation}/data/index"
      ${coreutils}/bin/chmod +w "${saveLocation}/data/index"
    ''
    + lib.optionalString newDf ''

      ${coreutils}/bin/mkdir -p "${saveLocation}/logs"
    ''
    + lib.optionalString enableTherapist ''

      export LD_PRELOAD="$LD_PRELOAD:${ptracerPkg}"
      echo starting dwarf therapist
      ${dwarf-fortress.dwarf-therapist}/bin/dwarftherapist > ${saveLocation}/therapy.log 2>&1 &
    '';
  df-script =
    df-base-script
    + ''

      exec ${environment}/run_df "$@"
    '';
  hack-script =
    df-base-script
    + ''

      ${coreutils}/bin/mkdir -p "${saveLocation}/dfhack-config"
      ${coreutils}/bin/touch "${saveLocation}/dfhack-config/command_counts.json"
    ''
    + lib.optionalString (!newDf) ''

      if ! [ -d "${saveLocation}/blueprints"  ]; then
          echo copying blueprints dir
          ${coreutils}/bin/cp -r "${dwarf-fortress.dfhack}/blueprints" "${saveLocation}/blueprints"
          ${coreutils}/bin/chmod --recursive +w "${saveLocation}/blueprints"
      fi
    ''
    + lib.optionalString newDf ''

      echo creating blueprints dir
      ${coreutils}/bin/mkdir -p "${saveLocation}/dfhack-config"
    ''
    + ''

      exec ${environment}/dfhack "$@"
    '';
in
writeShellScriptBin "dwarf-fortress${suffix}" (if enableDFHack then hack-script else df-script)

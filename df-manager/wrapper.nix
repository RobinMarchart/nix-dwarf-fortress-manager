{
  coreutils,
  dwarf-fortress,
  writeShellScriptBin,
  settingsPkg,
  settingsHackPkg,
  environmentPkg,
  enableDFHack ? false,
  enableTextMode ? false,
  enableTWBT ? false,
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
  df-script = ''
    set -e
    echo game directory: '${environment}'
    ${coreutils}/bin/mkdir -p "${saveLocation}/save"
    ${coreutils}/bin/mkdir -p "${saveLocation}/data/save"
    ${coreutils}/bin/touch "${saveLocation}/stderr.log"
    ${coreutils}/bin/touch "${saveLocation}/gamelog.txt"
    ${coreutils}/bin/touch "${saveLocation}/strace.log"
    ${coreutils}/bin/cp "${dwarf-fortress.dwarf-fortress}/data/index" "${saveLocation}/data/index"
    ${coreutils}/bin/chmod +w "${saveLocation}/data/index"
    export NIXPKGS_DF_HOME=${environment}
    exec ${environment}/run_df "$@"
  '';
  hack-script = ''
    set -e
    echo game directory: '${environment}'
    ${coreutils}/bin/mkdir -p "${saveLocation}/save"
    ${coreutils}/bin/mkdir -p "${saveLocation}/data/save"
    ${coreutils}/bin/mkdir -p "${saveLocation}/dfhack-config"
    ${coreutils}/bin/touch "${saveLocation}/stderr.log"
    ${coreutils}/bin/touch "${saveLocation}/gamelog.txt"
    ${coreutils}/bin/touch "${saveLocation}/strace.log"
    ${coreutils}/bin/touch "${saveLocation}/dfhack-config/command_counts.json"
    ${coreutils}/bin/cp "${dwarf-fortress.dwarf-fortress}/data/index" "${saveLocation}/data/index"
    ${coreutils}/bin/chmod +w "${saveLocation}/data/index"
    if ! [ -d "${saveLocation}/blueprints"  ]; then
        echo copying blueprints dir
        ${coreutils}/bin/cp -r "${dwarf-fortress.dwarf-fortress}/blueprints" "${saveLocation}/blueprints"
        ${coreutils}/bin/chmod --recursive +w "${saveLocation}/blueprints"
    fi
    export NIXPKGS_DF_HOME=${environment}
    exec ${environment}/dfhack "$@"
  '';
in
writeShellScriptBin "dwarf-fortress${suffix}" (if enableDFHack then hack-script else df-script)

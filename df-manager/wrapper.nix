{
  dwarf-fortress,
  writeShellScriptBin,
  settingsPkg,
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
  environment = environmentPkg.override {
    dwarf-fortress-unwrapped = dwarf-fortress.dwarf-fortress;
    dfhack = dwarf-fortress.dfhack;
    twbt = dwarf-fortress.twbt;
    settingsPkg = settings;
    inherit
      enableDFHack
      enableTWBT
      saveLocation
      modsList
      extraPackages
      ;
  };
in
writeShellScriptBin "dwarf-fortress${suffix}" ''
  set -e
  mkdir -p "${saveLocation}"
  cd "${environment}"
  exec LD_LIBRARY_PATH="''${LD_LIBRARY_PATH:+$LD_LIBRARY_PATH:}${environment}" ${environment}/dwarfort "$@"
''

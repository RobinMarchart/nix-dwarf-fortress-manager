{
  coreutils,
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
  df-script = ''
  set -e
  ${coreutils}/bin/mkdir -p "${saveLocation}"
  cd "${environment}"
  export LD_LIBRARY_PATH="''${LD_LIBRARY_PATH:+$LD_LIBRARY_PATH:}${environment}"
  exec ${environment}/dwarfort "$@"
'';
  hack-script = ''
  set -e
  PATH=''${PATH:+':'$PATH':'}
  if [[ $PATH != *':'''${coreutils}/bin''':'* ]]; then
      PATH=$PATH'${coreutils}/bin'
  fi
  PATH=''${PATH#':'}
  PATH=''${PATH%':'}
  export PATH
  ${coreutils}/bin/mkdir -p "${saveLocation}"
  cd "${environment}"
  export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:"${environment}/hack/libs":"${environment}/hack"
  exec ${environment}/hack/dfhack-run "$@"
'';
in
writeShellScriptBin "dwarf-fortress${suffix}" (if enableDFHack then hack-script else df-script)

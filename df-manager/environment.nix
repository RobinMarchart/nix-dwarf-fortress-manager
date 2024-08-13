{
  lib,
  buildEnv,
  dwarf-fortress-unwrapped,
  dfhack,
  twbt,
  settingsPkg,
  settingsHackPkg,
  enableDFHack ? false,
  enableTWBT ? false,
  # location where game saves should be kept
  saveLocation ? "/tmp/df-save",
  modsList ? [ ],
  extraPackages ? [ ],
}:
lib.throwIf (enableTWBT && (twbt == null || twbt == { }))
  "dwarf-fortress: TWBT enabled but package not set"
  lib.throwIf
  (enableTWBT && (twbt.dfVersion != dwarf-fortress-unwrapped.version))
  "dwarf-fortress: twbt and dwarf fortress have incopatible versions"
  lib.throwIf
  (enableDFHack && (dfhack.dfVersion != dwarf-fortress-unwrapped.version))
  "dwarf-fortress: dfhack and dwarf fortress have incopatible versions"
  lib.throwIf
  (enableTWBT && !enableDFHack)
  "dwarf-fortress: TWBT requires DFHack to be enabled"
  builtins.foldl'
  (
    next: mod:
    lib.throwIfNot
      (builtins.any (df-version: dwarf-fortress-unwrapped.version == df-version) mod.df-version)
      "dwarf-fortress: mod ${mod.name} is incompatible with game version ${dwarf-fortress-unwrapped.version}"
      next
  )
  (v: v)
  modsList
  (
    let
      mods-dir = buildEnv {
        name = "df-mods";
        paths = modsList;
      };
    in
    buildEnv {
      name = "df.environment";
      ignoreCollisions = true;
      paths =
        extraPackages
        ++ [ settingsPkg ]
        ++ lib.optional enableDFHack settingsHackPkg
        ++ [ mods-dir ]
        ++ lib.optional enableTWBT twbt
        ++ lib.optional enableDFHack dfhack
        ++ [ dwarf-fortress-unwrapped ];
      postBuild =
        ''
          echo linking mutable save files
          ln -s "${saveLocation}/save" "$out/save"
          ln -s "${saveLocation}/data/save" "$out/data/save"
          echo linking mutable log files
          ln -s "${saveLocation}/stderr.log" "$out/stderr.log"
          ln -s "${saveLocation}/gamelog.txt" "$out/gamelog.txt"
          ln -s "${saveLocation}/stderr.log" "$out/strace.log"
          echo linking mutable index file
          rm "$out/data/index"
          ln -s "${saveLocation}/data/index" "$out/data/index"
        ''
        + lib.optionalString enableDFHack ''

          echo linking mutable blueprint dir
          rm "$out/blueprints"
          ln -s "${saveLocation}/blueprints" "$out/blueprints"
        '';
    }
  )

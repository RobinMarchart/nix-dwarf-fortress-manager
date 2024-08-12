{
  lib,
  buildEnv,
  dwarf-fortress-unwrapped,
  dfhack,
  twbt,
  settingsPkg,
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
  (enableTWBT && (twbt.dfVersion == dwarf-fortress-unwrapped.version))
  "dwarf-fortress: twbt and dwarf fortress have incopatible versions"
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
        [ settingsPkg ]
        ++ extraPackages
        ++ [ mods-dir ]
        ++ lib.optional enableTWBT twbt
        ++ lib.optional enableDFHack dfhack
        ++ [ dwarf-fortress-unwrapped ];
      postBuild = ''
        ln -s "${saveLocation}" "$out/save"
      '';
    }
  )

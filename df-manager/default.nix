{
  stdenv,
  lib,
  runCommand,
  buildEnv,
  writeShellScriptBin,
  gawk,
  makeWrapper,
  dwarf-fortress,
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
}@options:
let
  settingsF = import ./settings.nix;
  environmentF = import ./environment.nix;
  wrapperF = import ./wrapper.nix;
  callWith =
    f: args:
    lib.makeOverridable f (builtins.intersectAttrs (builtins.functionArgs f) (options // args));
  settingsPkg = callWith settingsF {
    dfhack = dwarf-fortress.dfhack;
    dwarf-fortress-unwrapped = dwarf-fortress.dwarf-fortress;
    twbt = dwarf-fortress.twbt;
  };
  environmentPkg = callWith environmentF {
    dfhack = dwarf-fortress.dfhack;
    dwarf-fortress-unwrapped = dwarf-fortress.dwarf-fortress;
    twbt = dwarf-fortress.twbt;
    inherit settingsPkg;
  };
  wrapperPkg = callWith wrapperF { inherit settingsPkg environmentPkg; };
  packages = {
    settings = settingsPkg;
    environment = environmentPkg;
    wrapper = wrapperPkg;
  };
  packages' = lib.recurseIntoAttrs packages;
in
wrapperPkg // packages'

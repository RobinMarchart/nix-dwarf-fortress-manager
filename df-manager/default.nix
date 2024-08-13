{
  stdenv,
  lib,
  runCommand,
  buildEnv,
  writeShellScriptBin,
  writeShellScript,
  writeText,
  gawk,
  coreutils,
  util-linux,
  makeWrapper,

  dwarf-fortress,
}@options:
let
  settingsF = import ./settings.nix;
  settingsHackF = import ./settings-hack.nix;
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
  settingsHackPkg = callWith settingsHackF {
    dfhack = dwarf-fortress.dfhack;
    dwarf-fortress-unwrapped = dwarf-fortress.dwarf-fortress;
  };
  environmentPkg = callWith environmentF {
    dfhack = dwarf-fortress.dfhack;
    dwarf-fortress-unwrapped = dwarf-fortress.dwarf-fortress;
    twbt = dwarf-fortress.twbt;
    inherit settingsPkg settingsHackPkg;
  };
  wrapperPkg = callWith wrapperF { inherit settingsPkg settingsHackPkg environmentPkg; };
  packages = {
    settings = settingsPkg;
    settingsHack = settingsHackPkg;
    environment = environmentPkg;
    wrapper = wrapperPkg;
  };
  packages' = lib.recurseIntoAttrs packages;
in
wrapperPkg // packages'

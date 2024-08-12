{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    systems.url = "github:nix-systems/default";
    flake-utils = {
      url = "github:numtide/flake-utils";
      inputs.systems.follows = "systems";
    };
  };
  outputs =
    { nixpkgs, flake-utils, ... }:
    (flake-utils.lib.eachDefaultSystem (
      system:
      let
        mods = import ./mods;
        df-manager = import ./df-manager;
        pkgs = import nixpkgs {inherit system; config.allowUnfree = true;};
        callWith = f: args: f (builtins.intersectAttrs (builtins.functionArgs f) args);
      in
      {
        packages =
          let
            manager = callWith df-manager pkgs;
          in
          {
            default = manager;
            df-manager = manager;
            mods = callWith mods pkgs;
          };
        overlays = {
          default = final: prev: {
            dwarf-fortress-packages = prev.dwarf-fortress-packages.overrideScope (
              dffinal: dfprev: {
                mods = callWith mods final;
                df-manager = callWith df-manager final;
              }
            );
          };
          mods = final: prev: {
            dwarf-fortress-packages = prev.dwarf-fortress-packages.overrideScope (
              dffinal: dfprev: { mods = callWith mods final; }
            );
          };
          df-manager = final: prev: {
            dwarf-fortress-packages = prev.dwarf-fortress-packages.overrideScope (
              dffinal: dfprev: { df-manager = callWith df-manager final; }
            );
          };

        };

      }
    ))// {nixosModules.default = import ./module.nix;};
}

# home manager module
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.df-manager;
in
{
  options.df-manager = lib.mkOption {
    type =
      with lib.types;
      listOf (submodule {
        dwarf-fortress = lib.mkOption {
          type = package;
          default = pkgs.dwarf-fortress;
          example = pkgs.dwarf-fortress-packages.dwarf-fortress_0_47_05;
          description = "dwarf fortress package (with passthrough dwarf-fortress, dfhack, twbt)";
        };
        enableDFHack = lib.mkEnableOption "Use dfhack with this";
        enableTextMode = lib.mkEnableOption "Use text mode rendering";
        enableTWBT = lib.mkEnableOption "Use twbt rendering";
        enableTruetype = lib.mkEnableOption "enable truetype fonts";
        enableFPS = lib.mkEnableOption "enable showing fps";
        enableSound = lib.mkEnableOption "enable playing sound";
        dfSettings = lib.mkOption {
          type = attrsOf (attrsOf str);
          default = { };
          example = {
            d_init = {
              AUTOSAVE = "SEASONAL";
              INITIAL_SAVE = true;
            };
          };
          description = "additional settings";
        };
        saveLocation = lib.mkOption {
          type = str;
          default = "${config.home.homeDirectory}/dwarf-fortress/default-saves";
          description = "where game saves should be kept";
        };
        modsList = lib.mkOption {
          type = listOf package;
          default = [ ];
          example = with pkgs.dwarf-fortress-packages.mods; [ vettlingr ];
          description = "mods to install. derivation gets overlayed onto dwarf fortress folder.";
        };
        extraPackages = lib.mkOption {
          type = listOf package;
          default = [ ];
          description = "extra derivations that can overwrite anything but settings";
        };
        suffix = lib.mkOption {
          type = str;
          default = "";
          description = "suffix for launcher script. prevents conflicts with multiple concurrent installs";
        };
      });
    default = [ ];
    description = "dwarf fortress installs that should be prepared";
  };
  config.home.packages = map (
    manager:
    pkgs.dwarf-fortress-packages.df-manager.override {
      inherit (manager)
        dwarf-fortress
        enableDFHack
        enableTextMode
        enableTWBT
        enableTruetype
        enableFPS
        enableSound
        dfSettings
        saveLocation
        modsList
        extraPackages
        suffix
        ;
    }
  ) cfg;
}

# heaavily based on the wrapper in nixpkgs
{
  stdenv,
  lib,
  runCommand,
  gawk,
  makeWrapper,
  dwarf-fortress-unwrapped,
  dfhack,
  twbt,
  enableDFHack ? false,
  enableTextMode ? false,
  enableTWBT ? false,
  enableTruetype ? null,
  enableFPS ? false,
  enableSound ? true,
  # An attribute set of settings to override in data/init/*.txt.
  # For example, `init.FOO = true;` is translated to `[FOO:YES]` in init.txt
  dfSettings ? { },
}:
lib.throwIf (enableTWBT && (twbt == null || twbt == { })) "dwarf-fortress: TWBT enabled but package not set"
  lib.throwIf
  (enableTWBT && (twbt.dfVersion == dwarf-fortress-unwrapped.version))
  "dwarf-fortress: twbt and dwarf fortress have incopatible versions"
  lib.throwIf
  (enableTWBT && !enableDFHack)
  "dwarf-fortress: TWBT requires DFHack to be enabled"
  lib.throwIf
  (enableTWBT && enableTextMode)
  "dwarf-fortress: text mode and TWBT are mutually exclusive"
  (
    let
      settings' = lib.recursiveUpdate {
        init = {
          PRINT_MODE =
            if enableTextMode then
              "TEXT"
            else if enableTWBT then
              "TWBT"
            else if stdenv.hostPlatform.isDarwin then
              "STANDARD" # https://www.bay12games.com/dwarves/mantisbt/view.php?id=11680
            else
              null;
          TRUETYPE = enableTruetype;
          FPS = enableFPS;
          SOUND = enableSound;
        };
        d_init = { };
      } dfSettings;
      forEach = attrs: f: lib.concatStrings (lib.mapAttrsToList f attrs);
      toTxt =
        v:
        if lib.isBool v then
          if v then "YES" else "NO"
        else if lib.isInt v then
          toString v
        else if lib.isString v then
          v
        else
          throw "dwarf-fortress: unsupported configuration value ${toString v}";
    in
    runCommand "df-manager-settings"
      {
        nativeBuildInputs = [
          gawk
          makeWrapper
        ];
      }
      (
        ''
          mkdir -p $out/data/init

          edit_setting() {
            v=''${v//'&'/'\&'}
            if [ -f "$out/$file" ]; then
              if ! gawk -i inplace -v RS='\r?\n' '
                { n += sub("\\[" ENVIRON["k"] ":[^]]*\\]", "[" ENVIRON["k"] ":" ENVIRON["v"] "]"); print }
                END { exit(!n) }
              ' "$out/$file"; then
                echo "error: no setting named '$k' in $out/$file" >&2
                exit 1
              fi
            else
              echo "warning: no file $out/$file; cannot edit" >&2
            fi
          }
        ''
        + forEach settings' (
          file: kv:
          ''
            filename=${lib.escapeShellArg file}
            file=data/init/''${filename}.txt
            input_file_new="${dwarf-fortress-unwrapped}/data/init/''${filename}_default.txt"
            input_file="${dwarf-fortress-unwrapped}/$file"
            if [ -f "$input_file" ]; then
              cp "$input_file" "$out/$file"
            elif [ -f "$input_file_new" ]; then
              cp "$input_file_new" "$out/$file"
            else
              echo "warning: no file $input_file; cannot copy" >&2
            fi
          ''
          + forEach kv (
            k: v:
            lib.optionalString (v != null) ''
              export k=${lib.escapeShellArg k} v=${lib.escapeShellArg (toTxt v)}
              echo Setting $k to $v
              edit_setting
            ''
          )
        )
        + lib.optionalString enableDFHack ''
          mkdir -p $out/hack

          # Patch the MD5
          orig_md5=$(< "${dwarf-fortress-unwrapped}/hash.md5.orig")
          patched_md5=$(< "${dwarf-fortress-unwrapped}/hash.md5")
          input_file="${dfhack}/hack/symbols.xml"
          output_file="$out/hack/symbols.xml"

          echo "[DFHack Wrapper] Fixing Dwarf Fortress MD5:"
          echo "  Input:   $input_file"
          echo "  Search:  $orig_md5"
          echo "  Output:  $output_file"
          echo "  Replace: $patched_md5"

          substitute "$input_file" "$output_file" --replace-fail "$orig_md5" "$patched_md5"
        ''
      )
  )

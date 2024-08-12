{
  fetchzip,
  stdenvNoCC,
  lib,
  gnupatch,
  coreutils,
}:
let
  inherit (lib)
    importJSON
    licenses
    listToAttrs
    platforms
    makeOverridable
    ;
  dffd = listToAttrs (
    map (v: {
      name = v.name;
      value =
        let
          fetch =
            {
              version,
              rm,
              patches,
            }:
            let
              source = v.source.${version};
              baseLayout = fetchzip {
                stripRoot = false;
                pname = v.name;
                inherit (source) url hash;
                inherit version;
                passthru = {
                  inherit (source) df-version;
                };
                meta = {
                  license = licenses.unfree;
                  platforms = platforms.all;
                  inherit (v) description;
                };
                postFetch =
                  ''
                    echo removing hidden files
                    rm -rf "$out"/.*
                  ''
                  + (lib.optionalString (v.folder != null) ''
                    echo removing misc files
                    for file in $out/*; do
                        name=$(basename "$file")
                        if [[ "${v.folder}" != "$name" ]]; then
                            rm -r "$file"
                        fi
                    done
                    for dir in "$out"/"${v.folder}"/*/; do
                        mv "$dir" "$out/"
                    done
                    echo removing mod folder
                    rm -r "$out/${v.folder}"
                  '')
                  + lib.strings.concatMapStrings (path: "\nrm -r \"$out/${path}\"") source.rm;
              };
              # modify as requested by overrides
              modified = stdenvNoCC.mkDerivation {
                pname = v.name;
                inherit version;
                src = baseLayout;
                buildPhase =
                  ''
                    cp -r "$src" "$out"
                    chmod +w --recursive "$out"
                  ''
                  + lib.strings.concatMapStrings (path: "\nrm -r \"$out/${path}\"") rm
                  + "\ncd \"$out\""
                  + lib.strings.concatMapStrings (patch: "\npatch -p0 < \"${patch}\"") patches;
                passthru = {
                  inherit (source) df-version;
                };
                meta = {
                  license = licenses.unfree;
                  platforms = platforms.all;
                  inherit (v) description;
                };
              };
            in
            # only use override if necessairy
            if (rm == [ ]) && (patches == [ ]) then baseLayout else modified;
        in
        makeOverridable fetch {
          version = v.latest;
          rm = [ ];
          patches = [ ];
        };
    }) (importJSON ./dffd.json)
  );
in
lib.recurseIntoAttrs dffd

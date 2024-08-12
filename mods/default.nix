{ fetchzip, lib, gnupatch, coreutils }:
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
            { version, rm, patches }:
            let
              source = v.source.${version};
            in
            fetchzip {
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
                          ${coreutils}/bin/rm -r "$file"
                      fi
                  done
                  for dir in "$out"/"${v.folder}"/*/; do
                      ${coreutils}/bin/mv "$dir" "$out/"
                  done
                  echo removing mod folder
                  rm -r "$out/${v.folder}"
                '')
                + lib.strings.concatMapStrings (path: "\n${coreutils}/bin/rm -r \"$out/${path}\"") (source.rm ++ rm)
                + lib.strings.concatMapStrings (patch: "\n${gnupatch}/bin/patch -p0 < \"${patch}\"") patches;
            };
        in
          makeOverridable fetch { version = v.latest; rm = []; patches = []; };
    }) (importJSON ./dffd.json)
  );
in
lib.recurseIntoAttrs dffd

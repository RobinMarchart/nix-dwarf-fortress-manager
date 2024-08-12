{ fetchzip, lib }:
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
            { version }:
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
        in
        makeOverridable fetch { version = v.latest; };
    }) (importJSON ./dffd.json)
  );
in
lib.recurseIntoAttrs dffd

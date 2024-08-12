# Nix DwarfFortress Manager

this is an experimental approach to manage df entirely declarative. only the save folder is writable (it's a symlink to some user configured location) and everything else is in the nix store.
heavily borrows from the existing dwarf fortress wraper in nixpkgs

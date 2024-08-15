{ lib, stdenv }:
stdenv.mkDerivation {
  pname = "ptracer";
  version = "1";
  src = ./.;
  buildPhase = ''
    cc -xc $CFLAGS -fPIC $LDFLAGS -shared $src/ptracer.c -o $out
  '';
  meta = {
    license = lib.licenses.free;
    description = "preload library that enables ptracing for this process";
  };
}

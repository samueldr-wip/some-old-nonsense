{ lib
, runCommandNoCC
, squashfsTools
, ncdu
, tree
, fakeroot
}:

name: file: attrs: commands:

runCommandNoCC name (attrs // {
  nativeBuildInputs = [
    squashfsTools
    fakeroot
    ncdu
    tree
  ] ++ lib.optional (attrs ? nativeBuildInputs) attrs.nativeBuildInputs;
}) ''
  (PS4=" $ "; set -x
  mkdir -p $out
  fakeroot unsquashfs -quiet -dest fs "${file}"
  )
  (
  cd fs
  ${commands}
  )
  (PS4=" $ "; set -x
  mksquashfs fs $out/"$(basename ${file})" -quiet -comp xz -b $(( 1024 * 1024 )) -Xdict-size 100% -all-root
  unsquashfs -quiet -lls $out/"$(basename ${file})" | sed -e 's/^squashfs-root//' > $out/rootfs.ls
  )
  ncdu -0x -o $out/rootfs.ncdu ./fs
  tree rootfs > $out/rootfs.tree
''

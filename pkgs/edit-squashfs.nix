{ lib
, runCommandNoCC
, squashfsTools
}:

name: file: attrs: commands:

runCommandNoCC name (attrs // {
  nativeBuildInputs = [
    squashfsTools
  ] ++ lib.optional (attrs ? nativeBuildInputs) attrs.nativeBuildInputs;
}) ''
  (PS4=" $ "; set -x
  mkdir -p $out
  unsquashfs -quiet -no-xattrs -dest fs "${file}"
  )
  (
  cd fs
  ${commands}
  )
  (PS4=" $ "; set -x
  mksquashfs fs $out/"$(basename ${file})" -quiet -comp xz -b $(( 1024 * 1024 )) -Xdict-size 100% -all-root
  unsquashfs -quiet -lls $out/"$(basename ${file})" | sed -e 's/^squashfs-root//' > $out/rootfs.ls
  )
''

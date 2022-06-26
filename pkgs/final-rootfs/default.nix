{ lib
, rootfs
, editSquashfs
}:

editSquashfs "miyoo-mini-final-rootfs" "${rootfs}/rootfs.img" {} ''
  (PS4=" $ "; set -x

  rmdir appconfigs

  rm etc/init.d/udhcpc.script

  rm -r config/LCM
  rm -r config/wifi

  patch -p1 < ${./0001-etc-profile-Drop-now-unneeded-mount-commands.patch}
  )
''

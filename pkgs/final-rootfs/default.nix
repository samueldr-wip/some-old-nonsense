{ lib
, rootfs
, editSquashfs
, pkgsCross
, writeScript
}:

let
  init = writeScript "init" ''
    #!/bin/sh
    exec /linuxrc "$@"
  '';
in
editSquashfs "miyoo-mini-final-rootfs" "${rootfs}/rootfs.img" {} ''
  (PS4=" $ "; set -x

  rmdir appconfigs

  # Remove some weird stuff leftover
  rm -vr config/{wifi,LCM}
  rm -v etc/init.d/udhcpc.script customer/htop customer/kill_apps.sh
  rmdir -v vendor

  ln -s /mnt/SDCARD/.appconfigs appconfigs

  patch -p1 < ${./0001-etc-profile-Drop-now-unneeded-mount-commands.patch}
  patch -p1 < ${./0002-misc-rework.patch}
  patch -p1 < ${./0001-main-somewhat-make-a-bit-more-user-friendly.patch}
  patch -p1 < ${./0001-modules-Drop-modules-not-present-in-vendor-image.patch}
  patch -p1 < ${./0001-main-Cleanup-and-add-compat-for-appconfigs.patch}
  patch -p1 < ${./0001-passwd-update-root-entry.patch}
  patch -p1 < ${./0001-main-Support-just-enough-vendor-MainUI-launching-for.patch}
  patch -p1 < ${./0001-main-Don-t-exec.patch}
  patch -p1 < ${./0001-Mount-gocfw-userdata-to-SDCARD.patch}
  patch -p1 < ${./0001-modules-Only-retry-loading-if-needed.patch}
  patch -p1 < ${./0001-mount-Don-t-overwrite-devtmpfs.patch}
  cat ${pkgsCross.armv7l-hf-multiplatform.pkgsStatic.busybox}/bin/busybox > bin/busybox
  cp ${init} init
  mkdir run
  mkdir vendor
  )
''

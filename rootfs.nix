/*

This takes a stock update image and rekejiggers it into a single squashfs
rootfs.

The vendor image is split in multiple partitions, making it more awkward than
necessary to deal with.

Stock flash map:

```
mtd0: 00060000 00010000 "BOOT"
mtd1: 00200000 00010000 "KERNEL"
mtd2: 00010000 00010000 "KEY_CUST"
mtd3: 00020000 00010000 "LOGO"
mtd4: 001c0000 00010000 "rootfs"    
mtd5: 00370000 00010000 "miservice" 
mtd6: 00770000 00010000 "customer"  
mtd7: 000d0000 00010000 "appconfigs"
```

 - The `rootfs` partition is used as `root=` kernel parameter.
 - The `miservice` partition is mounted under `/config`.
 - The `customer` partition is mounted under `/customer`.
 - The `appconfigs` is mounted under `appconfigs`.

All partitions except `appconfigs` are squashfs xz compressed.

The `rootfs` contains a base Linux system, with `/etc/profile` being used to
mount the other partitions and launch `/customer/demo.sh`.
The base Linux system seems mostly unremarkable.

The `miservice` partition (`/config`) mostly holds device-specific files. The
kernel modules, and device-specific userspace libraries.

The `customer` partition contains the "app"; the GUI that is interactable by
from the vendor. There isn't much that is remarkable in there, except for the
`autosd.sh` script (used to mount the SD card), and *maybe* the libs that could
be looked at with e.g. ghidra to see what the vendor did. From that partition,
mainly the launcher scripts are important. They will be distilled down to a
"compatible" form in the first stage.

The `appconfigs` partition is a writable JFFS partition used to write the
user config. This isn't good to see on an SPI flash, especially since it's not
visibly a good brand flash chip (unknown vendor, using another vendor's chip
identifier).

*/

{ lib
, runCommandNoCC
, unzip
, squashfsTools
, ncdu
, tree
}:

let
  inherit (lib) concatStringsSep;
in
runCommandNoCC "miyoomini-combined-rootfs" {
  # XXX: provide the file with the thing that requires manually adding to the store.
  zip = ./Miyoo-mini-upgrade20220419.zip;
  zip_firmware = "The firmware0419/miyoo283_fw.img";

  nativeBuildInputs = [
    squashfsTools
    unzip
    ncdu
    tree
  ];
} ''
  # Uses the updater script to create calls to the _extract function.
  parse_updater() {
    dd status=none if="$zip_firmware" bs=$((0x4000)) count=1 \
      | grep '^fatload\|mxp r.info' \
      | sed '/^mxp/N;s/\n/ /' \
      | grep -i 'rootfs\|miservice\|customer' \
      | sed -e 's/mxp r.info/_extract/' -e 's/\s*fatload mmc 0 0x21000000\s*/ /' -e 's/\s*\$(SdUpgradeImage)\s*/ /'
  }

  _extract() {
    part="$1"; shift
    bytes=$1; shift
    pos=$1; shift

    (PS4=" $ "; set -x
    dd status=none if="$zip_firmware" bs=$(( bytes )) iflag=skip_bytes skip=$(( pos )) count=$(( 1 )) of="$part.img"
    )
  }

  # Extract only the SPI flash updater
  unzip "$zip" "$zip_firmware"

  # echo "Script:"
  # parse_updater
  # echo

  # Extract the discrete partitions
  eval "$(parse_updater)"

  for f in *.img; do
    (PS4=" $ "; set -x
    unsquashfs -quiet -no-xattrs -dest ''${f/.img/} "$f"
    )
  done

  rmdir rootfs/customer
  mv customer rootfs/customer

  rmdir rootfs/config
  mv miservice rootfs/config

  mkdir -p $out
  (PS4=" $ "; set -x
  mksquashfs rootfs $out/rootfs.img -quiet -comp xz -b $(( 1024 * 1024 )) -Xdict-size 100%
  )
  ncdu -0x -o $out/rootfs.ncdu ./rootfs
  unsquashfs -quiet -ls $out/rootfs.img | sed -e 's/^squashfs-root//' > $out/rootfs.ls
  tree rootfs > $out/rootfs.tree
''

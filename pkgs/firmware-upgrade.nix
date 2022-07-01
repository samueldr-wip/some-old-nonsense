{ lib
, runCommandNoCC
, rootfs
, writeText
}:

let
  bootargs = lib.concatStringsSep " " [
    # Vendor boot args
    "console=ttyS0,115200"
    "root=/dev/mtdblock4"
    "rootfstype=squashfs"
    "ro"
    "init=/linuxrc"
    "LX_MEM=0x7f00000"
    "mma_heap=mma_heap_name0,miu=0,sz=0x1500000"
    "mma_memblock_remove=1"
    "highres=off"
    "mmap_reserved=fb,miu=0,sz=0x300000,max_start_off=0x7C00000,max_end_off=0x7F00000"

    # Makes it reset on panic, instead of being stuck.
    "panic=1"

    # This is the main important addition;
    # The `rootfs` partition is the last partition, and subsumes the following ones.
    "mtdparts=NOR_FLASH:0x00060000(BOOT)ro,0x00200000(KERNEL)ro,0x00010000(KEY_CUST)ro,0x00020000(LOGO),-(rootfs)"#,0x00370000(miservice),0x00770000(customer),0x000d0000(appconfigs)"
  ];

  version = "20220625.001";
  payloadOffset = "0x4000";  # The vendor U-Boot will read 0x4000 bytes for the script.
  rootfsOffset = "0x290000"; # Partition offset
  rootfsSize =   "0xd70000"; # Partition size (subsuming following partitions)
  updateScript = writeText "update-script" ''
    build:mod-${version}

    # Enable the SPI Flash
    sf probe 0

    # Read all of the payload
    fatload mmc 0 0x21000000 $(SdUpgradeImage) 0 ${payloadOffset}

    # Write the rootfs
    sf update 0x21000000 ${rootfsOffset} ${rootfsSize}

    # Update boot args
    env set bootargs '${bootargs}'

    # the next `env set` command needs to be less than 64 words long.
    # So let's use `run` for buzzing about
    env set buzz 'gpio out 48 0; sleepms 100; gpio out 48 1; sleepms 150'

    # Update boot command
    env set bootcmd '${
      lib.concatStringsSep "; " [

        # > force the mosfet that connects the battery to the system on.
        #  — https://github.com/linux-chenxing/linux-chenxing.org/discussions/41#discussioncomment-3024610
        #  — https://github.com/linux-chenxing/linux/blob/65c255cdc9e1e758558dd3ab7e39d565f9863e02/arch/arm/boot/dts/mstar-infinity2m-ssd202d-miyoo-mini.dts#L178
        "gpio out 85 1"

        # Run the custom boot command (if present)
        "run mybootcmd"

        # Vibrate to tell the user it's attempting the default boot sequence.
        "run buzz"
        "run buzz"

        # Vendor boot commands
        "bootlogo 0 0 0 0 0"

        # (Unclear what this does, present in vendor startup sequence)
        "mw 1f001cc0 11"

        # (Unclear what this does, present in vendor startup sequence)
        "gpio out 8 0"

        # Read the kernel from SPI Flash
        "sf probe 0"
        "sf read 0x22000000 \${sf_kernel_start} \${sf_kernel_size}"

        # (Unclear what this does, present in vendor startup sequence)
        "gpio out 8 1"

        # Powers the backlight
        "gpio out 4 1"

        # Boots previously loaded kernel
        "bootm 0x22000000"
      ]
    }'

    # Just in case, those are used by the vendor command
    env set sf_kernel_size 200000
    env set sf_kernel_start 60000

    # Version for the OS
    env set miyoo_version mod-${version}

    env save

    reset

    % # End of script
  '';
in
runCommandNoCC "miyoo-mini-mod-${version}" {
  inherit rootfs;
} ''
  (PS4=" $ "; set -x
  mkdir -p $out
  # Start the firmware image with the update script
  cat "${updateScript}" > "$out/miyoo283_fw.img"
  # Pad the rootfs payload to the size of the SPI flash, makes the script easier to write.
  dd if="/dev/zero"   of="payload.img"          bs=$(( ${rootfsSize} )) count=$(( 1 )) conv=notrunc
  # Write the rootfs in the NULL padded file
  dd if="$rootfs"     of="payload.img"          bs=1024 conv=notrunc

  # Append the whole payload starting at payloadOffset to the firmware image
  dd if="payload.img" of="$out/miyoo283_fw.img" bs=$((${payloadOffset})) seek=1 conv=notrunc
  )
''

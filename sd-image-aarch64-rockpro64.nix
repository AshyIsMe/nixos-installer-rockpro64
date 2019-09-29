# To build, use:
# nix-build nixos -I nixos-config=nixos/modules/installer/cd-dvd/sd-image-aarch64.nix -A config.system.build.sdImage
{ config, lib, pkgs, systems, ... }:

let
  extlinux-conf-builder =
    import ../../system/boot/loader/generic-extlinux-compatible/extlinux-conf-builder.nix {
      pkgs = pkgs.buildPackages;
    };

  # It might be possible to crosscompile everything. 
  # See lopsided98's nixpkgs fork master-custom branch:
  # https://github.com/lopsided98/nixpkgs/commit/b7b55f61cda24de3de3a6346c8c2b666e8fec094
  # pkgsAarch64LinuxCross = self.forceCross {
  #   system = "x86_64-linux";
  #   platform = systems.platforms.pc64;
  # } systems.examples.aarch64-multiplatform;

  linux_rock64_4_20 = pkgs.callPackage ./linux-rock64/4.20.nix {
    kernelPatches = [ pkgs.kernelPatches.bridge_stp_helper ];
  };
  linux_rock64_5_3 = pkgs.callPackage ./linux-rock64/5.3.nix {
    kernelPatches = [ pkgs.kernelPatches.bridge_stp_helper ];
  };

  linuxPackages_rock64_4_20 = pkgs.recurseIntoAttrs (pkgs.linuxPackagesFor linux_rock64_4_20);
  linuxPackages_rock64_5_3 = pkgs.recurseIntoAttrs (pkgs.linuxPackagesFor linux_rock64_5_3);

in
{
  imports = [
    ../../profiles/base.nix
    ../../profiles/installation-device.nix
    ./sd-image.nix
  ];

  boot = {
    loader = {
      grub.enable = false;
      generic-extlinux-compatible.enable = true;
    };
    #kernelPackages = lib.mkForce pkgs.pkgsAarch64LinuxCross.linuxPackages_rock64_5_3;
    #kernelPackages = linuxPackages_rock64_5_3;
    kernelPackages = linuxPackages_rock64_4_20;
  };

  boot.consoleLogLevel = lib.mkDefault 7;

  # The serial ports listed here are:
  # - ttyS0: for Tegra (Jetson TX1)
  # - ttyAMA0: for QEMU's -machine virt
  # Also increase the amount of CMA to ensure the virtual console on the RPi3 works.
  boot.kernelParams = ["cma=32M" "console=ttyS0,115200n8" "console=ttyAMA0,115200n8" "console=tty0"];

  boot.initrd.availableKernelModules = [
    # Allows early (earlier) modesetting for the Raspberry Pi
    "vc4" "bcm2835_dma" "i2c_bcm2835"
    # Allows early (earlier) modesetting for Allwinner SoCs
    "sun4i_drm" "sun8i_drm_hdmi" "sun8i_mixer"
  ];

  sdImage = {
    populateFirmwareCommands = let
      configTxt = pkgs.writeText "config.txt" ''
        kernel=u-boot-rpi3.bin

        # Boot in 64-bit mode.
        arm_control=0x200

        # U-Boot used to need this to work, regardless of whether UART is actually used or not.
        # TODO: check when/if this can be removed.
        enable_uart=1

        # Prevent the firmware from smashing the framebuffer setup done by the mainline kernel
        # when attempting to show low-voltage or overtemperature warnings.
        avoid_warnings=1
      '';
      in ''
        (cd ${pkgs.raspberrypifw}/share/raspberrypi/boot && cp bootcode.bin fixup*.dat start*.elf $NIX_BUILD_TOP/firmware/)
        cp ${pkgs.ubootRaspberryPi3_64bit}/u-boot.bin firmware/u-boot-rpi3.bin
        cp ${configTxt} firmware/config.txt
      '';
    populateRootCommands = ''
      mkdir -p ./files/boot
      ${extlinux-conf-builder} -t 3 -c ${config.system.build.toplevel} -d ./files/boot
    '';
  };

  # the installation media is also the installation target,
  # so we don't want to provide the installation configuration.nix.
  installer.cloneConfig = false;
}

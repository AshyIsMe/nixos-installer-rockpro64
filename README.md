# Create a nixos installer for the RockPro64

The RockPro64 currently is not yet fully upstreamed into uboot and the kernel and as such the generic nixos installer will not boot


## Building

There is no cross-compiling support in this repo currently so this must be built on a aarch64 machine (or possibly an emulated aarch64 qemu vm).
It has been tested on a c2.large.arm machine on packet.net.

Note: Currently you need to build on the nixos-unstable channel (20.03pre at the moment) as the image produced by stable 19.03 does not boot.

```
# To build, use:
nix-build '<nixpkgs/nixos>' -I nixos-config=sd-image-aarch64-rockpro64.nix -A config.system.build.sdImage

# When it completes the image will be in the result symlink dir:
find result/ -iname "*.img"
# result/sd-image/nixos-sd-image-19.03pre-git-aarch64-linux.img


```

## Make a bootable sdcard


In the below commands replace mmcblkX with the correct sdcard device.

```
# Copy the image to the sdcard
sudo dd if=nixos-sd-image-19.03pre-git-aarch64-linux.img of=/dev/mmcblkX status=progress

# Use fdisk to delete first partition. 
# (The first partition currently contains firmware for other boards and is not useful for the rockpro64.
#  It also gets in the way of uboot currently.)

sudo fdisk /dev/mmcblkX
# Delete first partition and write: d 1 w
```

Now copy the rockpro64 specific uboot build to the sdcard.
The correct uboot build can be found here: <https://hydra.nixos.org/job/nixpkgs/trunk/ubootRockPro64.aarch64-linux>
See <https://nixos.wiki/wiki/NixOS_on_ARM/PINE64_ROCKPro64> for more information.
```
# Copy the uboot image to the sdcard starting at block 64
sudo dd if=idbloader.img of=/dev/mmcblkX status=progress bs=512 seek=64

```

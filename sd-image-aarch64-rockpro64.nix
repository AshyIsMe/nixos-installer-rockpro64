{ config, lib, pkgs, systems, ... }:
let
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
    <nixpkgs/nixos/modules/installer/cd-dvd/sd-image-aarch64.nix>
  ];
  # put your own configuration here, for example ssh keys:
  #users.extraUsers.root.openssh.authorizedKeys.keys = [
  #   "ssh-ed25519 AAAAC3NzaC1lZDI1.... username@tld"
  #];

  boot = {
    loader = {
      grub.enable = false;
      generic-extlinux-compatible.enable = true;
    };
    #kernelPackages = linuxPackages_rock64_5_3;
    kernelPackages = linuxPackages_rock64_4_20;
  };
}

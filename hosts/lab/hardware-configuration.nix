# プレースホルダー（実機がまだないので手で書いたもの）。
# インストール時に nixos-anywhere の
#   --generate-hardware-config nixos-generate-config ./hosts/lab/hardware-configuration.nix
# で実機から生成したものに置き換えてコミットする（docs/homelab.md）。
# ファイルシステムは disko.nix が定義するので、ここには書かない。
{
  config,
  lib,
  modulesPath,
  ...
}:
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot.initrd.availableKernelModules = [
    "xhci_pci"
    "thunderbolt"
    "nvme"
    "usb_storage"
    "sd_mod"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}

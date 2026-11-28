# node1：壊さない土台（dynabook GX83/MLE、i7-10510U、RAM 8GB、NVMe 512GB）
{ ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./disko.nix
  ];

  networking.hostName = "base";
}

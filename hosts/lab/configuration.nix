# node2：壊していい実験機（Dell Inspiron 7300、i7-1165G7、RAM 8GB、NVMe 512GB）
{ ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./disko.nix
  ];

  networking.hostName = "lab";
}

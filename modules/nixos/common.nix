# base / lab 共通の NixOS 設定（ホームラボの土台）
{
  config,
  lib,
  pkgs,
  username,
  ...
}:
let
  # Mac（~/.ssh/id_ed25519.pub）の公開鍵。秘密鍵はリポジトリに置かない。
  sshKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIL560px8Ual9lDs282MqiPARQ+orPy4d55JlC3MIu/qg shuya@mac"
  ];
in
{
  # ---- ブート ----
  # Secure Boot は BIOS で無効にしておく（docs/homelab.md）
  boot.loader.systemd-boot.enable = true;
  boot.loader.systemd-boot.configurationLimit = 10;
  boot.loader.efi.canTouchEfiVariables = true;
  # 蓋を開けたまま置いたときに画面を消す（60 秒）
  boot.kernelParams = [ "consoleblank=60" ];

  # USB-LAN アダプタ（r8152 など）のファームウェア
  hardware.enableRedistributableFirmware = true;

  # ---- ネットワーク ----
  # 有線（USB-LAN、インターフェース名は enx<MAC>）を DHCP で使う。Wi-Fi は設定しない。
  networking.useDHCP = lib.mkDefault true;
  networking.firewall = {
    enable = true;
    # Tailscale の中からは全ポートを許可。外向きに開けるのは SSH(22) と Tailscale の UDP だけ。
    trustedInterfaces = [ "tailscale0" ];
    allowedUDPPorts = [ config.services.tailscale.port ];
  };

  services.tailscale.enable = true;

  # ---- SSH：鍵認証だけ ----
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  # ---- ユーザー ----
  users.mutableUsers = true;
  users.users.${username} = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = sshKeys;
  };
  # パスワードを持たないユーザーで --target-host デプロイするため、wheel の sudo はパスワードなし。
  # SSH は鍵だけなので、sudo できるのは鍵を持つ Mac からだけ。
  security.sudo.wheelNeedsPassword = false;

  # ---- 蓋を閉じても止まらない・サスペンドしない ----
  services.logind.settings.Login = {
    HandleLidSwitch = "ignore";
    HandleLidSwitchExternalPower = "ignore";
    HandleLidSwitchDocked = "ignore";
    HandleSuspendKey = "ignore";
    HandleHibernateKey = "ignore";
    IdleAction = "ignore";
  };
  systemd.sleep.settings.Sleep = {
    AllowSuspend = "no";
    AllowHibernation = "no";
    AllowHybridSleep = "no";
    AllowSuspendThenHibernate = "no";
  };
  systemd.targets = {
    sleep.enable = false;
    suspend.enable = false;
    hibernate.enable = false;
    hybrid-sleep.enable = false;
  };

  # Intel ノート向け：温度管理。メモリが 8GB なので zram で圧縮スワップを持つ。
  services.thermald.enable = true;
  zramSwap.enable = true;

  # ---- 監視 ----
  # 9100/tcp。firewall では開けないので、届くのは tailscale0 経由だけ。
  services.prometheus.exporters.node = {
    enable = true;
    enabledCollectors = [ "systemd" ];
  };

  # ---- Nix ----
  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    # Mac から nixos-rebuild --target-host でストアパスを送るため
    trusted-users = [
      "root"
      "@wheel"
    ];
  };
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };
  nix.optimise.automatic = true;

  # ---- 時刻・ロケール ----
  time.timeZone = "Asia/Tokyo";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocales = [ "ja_JP.UTF-8/UTF-8" ];

  environment.systemPackages = with pkgs; [
    git
    vim
    htop
    pciutils
    usbutils
    ethtool
  ];

  # 初めて入れたときの NixOS のバージョン。後から変えない。
  system.stateVersion = "26.05";
}

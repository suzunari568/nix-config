# ホームラボ（NixOS）

ノート PC 2 台を NixOS のサーバーにして、この flake で管理します。
外には公開せず、Tailscale の中だけで使います。
設計図（全体・各マシンの中・デプロイ／監視／バックアップの流れ）は [homelab-design.md](homelab-design.md) にあります。

| 名前 | 役割 | 機種 | CPU | RAM | ディスク |
| --- | --- | --- | --- | --- | --- |
| `base`（node1） | 壊さない土台 | dynabook GX83/MLE | i7-10510U | 8GB | NVMe 512GB |
| `lab`（node2） | 壊していい実験機 | Dell Inspiron 7300 | i7-1165G7 | 8GB | NVMe 512GB |

## ファイル

| ファイル | 内容 |
| --- | --- |
| `flake.nix` | `nixosConfigurations.base` / `.lab`。入力は `nixpkgs-nixos`（`nixos-26.05`）と `disko` |
| `modules/nixos/common.nix` | 2 台共通：ユーザー、SSH（鍵だけ）、Tailscale、蓋を閉じても止まらない設定、firewall、node exporter、Nix の gc など |
| `hosts/<host>/configuration.nix` | ホスト名など、ホストごとの設定 |
| `hosts/<host>/disko.nix` | ディスク構成。`/dev/nvme0n1` に GPT、ESP（1GiB）＋ btrfs |
| `hosts/<host>/hardware-configuration.nix` | **今はプレースホルダー**。インストール時に実機から生成したものに置き換える |

この PR の時点で入っているのは土台だけです。Caddy、DNS、Prometheus＋Grafana、incus、k3s などは後の PR で足します。

### 共通設定のポイント

- ユーザーは `shuya`（Mac と同じ）。`wheel` に入っていて、sudo はパスワードなし（ユーザーにパスワードを付けずに `--target-host` でデプロイするため）。
- SSH は公開鍵だけ。パスワードログインと root ログインはできません。登録している鍵は Mac の `~/.ssh/id_ed25519.pub` です。
- 有線 LAN（USB-LAN アダプタ）を DHCP で使います。Wi-Fi は設定していません。
- firewall は有効です。外から開いているのは SSH（22/tcp）と Tailscale（41641/udp）だけで、`tailscale0` からは全部通します。node exporter（9100/tcp）にも Tailscale 経由でしか届きません。
- 蓋を閉じても、AC につないでいても止まりません。サスペンドとハイバネートは無効です。画面は 60 秒で消えます。
- ディスクを消す設定なので、**`disko.nix` の `device` が実機のディスクと合っているか、入れる前に必ず確認してください。**

## インストールの前に用意するもの

- [ ] 8GB 以上の USB メモリ（中身は消えます）
- [ ] USB-LAN アダプタ 2 個と LAN ケーブル（DHCP が使えるルーターにつなぐ）
- [ ] 2 台とも、消してよいことの確認（NVMe は全部消えます）
- [ ] Tailscale のアカウント（Mac がすでに tailnet に入っていること）
- [ ] Mac の `~/.ssh/id_ed25519.pub` が `modules/nixos/common.nix` の鍵と同じであること

## 1. USB インストーラーを作る（Mac）

1. NixOS 26.05 の **Minimal ISO（x86_64）** を <https://nixos.org/download/#nixos-iso> からダウンロードする。
2. USB メモリを挿して、デバイス名を確かめる。

   ```sh
   diskutil list   # 例：/dev/disk4 （external, physical）
   ```

3. 書き込む（`disk4` は自分の環境に合わせる。間違えると Mac のディスクが消えます）。

   ```sh
   diskutil unmountDisk /dev/disk4
   sudo dd if=nixos-minimal-26.05-x86_64-linux.iso of=/dev/rdisk4 bs=4m status=progress
   diskutil eject /dev/disk4
   ```

## 2. BIOS の設定

どちらの機種も、電源を入れた直後に **F2** で BIOS 設定、**F12** で起動メニューです。
項目名は BIOS のバージョンで違うことがあります。「あれば」と書いた項目は、無ければ飛ばしてかまいません。

| 項目 | 設定 | 理由 |
| --- | --- | --- |
| Secure Boot | **無効** | NixOS の systemd-boot は署名していないため |
| ストレージのモード（Dell：SATA/NVMe Operation） | **RAID On / Intel RST（VMD）なら AHCI/NVMe に変える** | RST/VMD のままだと Linux から NVMe が見えないことがある。Windows はもう使わないので変えてよい |
| 充電上限（Dell：Battery Charge Configuration、dynabook：「eco 充電」など） | あれば **Primarily AC Use** か上限 80% 前後 | ずっと AC につないだままなので、電池を長持ちさせる |
| AC 接続で自動起動（Dell：Power On with AC / Wake on AC など） | あれば **有効** | 停電から戻ったときに自動で起動させる |
| 起動順 | USB を先に（または毎回 F12 で選ぶ） | インストーラーを起動するため |
| Fast Boot | あれば無効 | USB から起動しやすくするため |

## 3. インストーラーで起動して SSH できるようにする（ノート PC）

1. USB-LAN アダプタと USB メモリを挿して、F12 から USB で起動する。
2. 起動したら（ユーザー `nixos` で自動ログインしている）、IP アドレスを確かめて、一時的なパスワードを付ける。

   ```sh
   ip -4 addr        # enx... というインターフェースに 192.168.x.x が付いていれば OK
   passwd            # インストーラーの nixos ユーザーのパスワード（インストール後は消える）
   ```

3. Mac から鍵を入れて、パスワードなしで入れることを確かめる。

   ```sh
   ssh-copy-id nixos@192.168.x.x
   ssh nixos@192.168.x.x 'lsblk'    # nvme0n1 が見えること
   ```

   `nvme0n1` 以外の名前になっていたら、`hosts/<host>/disko.nix` の `device` を直してから進めてください。

## 4. nixos-anywhere で入れる（Mac）

このリポジトリのルートで実行します。**ディスクは全部消えます。**

```sh
# base（dynabook）の例。lab のときは base を lab に置き換える
nix run github:nix-community/nixos-anywhere -- \
  --flake .#base \
  --target-host nixos@192.168.x.x \
  --build-on remote \
  --generate-hardware-config nixos-generate-config ./hosts/base/hardware-configuration.nix
```

- `--generate-hardware-config nixos-generate-config <パス>`：実機で `nixos-generate-config` を実行して、プレースホルダーの `hardware-configuration.nix` を置き換えます（ファイルシステムは disko が持つので、`--no-filesystems` 付きで生成されます）。
- `--build-on remote`：Mac（aarch64-darwin）では x86_64-linux をビルドできないので、インストーラーの上でビルドします。ほとんどは cache.nixos.org から落ちてきます。
- 終わると自動で再起動します。USB メモリを抜いておいてください。

生成された `hardware-configuration.nix` は、確認してコミットします。

```sh
git diff hosts/base/hardware-configuration.nix
git add hosts/base/hardware-configuration.nix
git commit -m "base: Use the generated hardware-configuration.nix"
```

## 5. 再起動後の確認と Tailscale

```sh
ssh shuya@192.168.x.x          # 鍵で入れること
ssh shuya@192.168.x.x 'sudo tailscale up'   # 表示された URL を Mac のブラウザで開いて承認
```

- Tailscale の管理画面で、そのマシンの **Key expiry を無効** にしておくと、鍵の期限切れで切れなくなります。
- 以後は MagicDNS の名前（`base` / `lab`）で入れます：`ssh shuya@base`
- 手元でコンソールから入る必要があるときのために、パスワードを付けておいてもかまいません（SSH はパスワードでは入れないまま）：`sudo passwd shuya`

## 6. その後のデプロイ（Mac）

設定を変えたら、Mac から次のように反映します。ビルドは相手のマシンでします。

```sh
nix run nixpkgs#nixos-rebuild -- switch \
  --flake .#base \
  --target-host shuya@base \
  --build-host shuya@base \
  --sudo
```

- `--sudo`：相手のマシンで sudo を使って切り替えます（wheel はパスワードなし）。
- 切り替える前に試したいときは `switch` の代わりに `test`（再起動すると元に戻る）や `build`。
- 失敗したら、相手のマシンで `sudo nixos-rebuild switch --rollback`、または起動メニューで前の世代を選びます。
- `lab` は壊してよいので先に試し、問題がなければ `base` に入れる、という順番にします。

評価だけなら Mac でもできます。

```sh
nix eval .#nixosConfigurations.base.config.system.build.toplevel.drvPath
nix eval .#nixosConfigurations.lab.config.system.build.toplevel.drvPath
```

## nixpkgs の更新

NixOS 用の nixpkgs は Mac 用とは別の入力（`nixpkgs-nixos`）です。サーバーだけ更新するときは次のようにします。

```sh
nix flake update nixpkgs-nixos disko
```

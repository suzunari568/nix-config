# nix設定

Apple Silicon の Mac（ユーザー `shuya`、ホスト設定 `shuya-aarch64-darwin`）を nix-darwin + home-manager + Homebrew で管理する設定です。
通常は `/etc/nix-darwin` に clone して使います。

ホームラボの NixOS マシン（`base`、`lab`）も同じ flake で管理しています。手順は [docs/homelab.md](docs/homelab.md) を見てください。

## 何をどこで管理しているか

| 対象 | 管理先 | ファイル |
| --- | --- | --- |
| macOS の設定（Dock、Finder、スクリーンショット） | nix-darwin | `flake.nix`（`darwinModules.base`） |
| Nix 本体の設定 | Determinate Nix モジュール | `flake.nix`（`darwinModules.determinateNixConfig`） |
| `~/.zshenv`・`~/.zprofile`・`~/.zshrc` | home-manager（`programs.zsh`） | `home.nix` |
| git の設定（`~/.config/git/config`） | home-manager（`programs.git`） | `home.nix` |
| `~/.ssh/config` | home-manager（`programs.ssh`） | `home.nix` |
| CLI ツール（fzf, gh, ghq, git, neovim, vim, sheldon, starship, zoxide, tree, tenv, sqlite, ffmpeg, watchman） | home-manager（`home.packages`） | `home.nix` |
| 開発用 CLI ツール（bat, delta, eza, fd, gh-dash, lazygit, ripgrep, shellcheck, uv） | home-manager（`home.packages`） | `home.nix` |
| direnv + nix-direnv（`~/.zshrc` にフックを追加） | home-manager（`programs.direnv`） | `home.nix` |
| GUI アプリ（cask）、tap、Mac App Store アプリ、VS Code 拡張 | nix-darwin の `homebrew` モジュール | `homebrew.nix` |
| Homebrew に残すフォーミュラ（go, python@3.13, openjdk, mise, libpq, mas, docker-compose, runpodctl） | nix-darwin の `homebrew` モジュール | `homebrew.nix` |
| 言語ランタイム（Python, Go, Java） | mise（Nix では管理しない） | `~/.config/mise/config.toml` を home-manager（`programs.mise`）で生成。`home.nix` |

補足:

- SSH の秘密鍵など、`~/.ssh/config` 以外のファイルは管理しません。
- 公開リポジトリに載せたくないホスト（RunPod など）は、管理対象外の `~/.ssh/config.local` に書きます。`~/.ssh/config` が `Include config.local` で読み込みます。
- sheldon・neovim などの各ツール自体の設定（`~/.config/sheldon` など）は、これまでどおり手で管理します。mise はグローバル設定（`~/.config/mise/config.toml`）だけを home-manager で管理し、mise 本体は Homebrew のままです。
- delta はインストールするだけで、git の pager には設定していません。使う場合は `programs.delta.enable = true;` と `programs.delta.enableGitIntegration = true;` を追加してください。
- jq は macOS 標準の `/usr/bin/jq`（1.7.1）があるので追加していません。
- `homebrew.onActivation` は `cleanup = "none"`、`autoUpdate = false`、`upgrade = false` にしています。適用しても Homebrew のアプリがアンインストールやアップグレードされることはありません。

## 言語ランタイムの出どころ（2026-11 時点）

言語ランタイムは Nix に移さず、mise で管理する方針です。現時点で実際に PATH の先頭に来ているものは次のとおりです。

| ランタイム | 使われているもの | 入れたもの | 備考 |
| --- | --- | --- | --- |
| Node.js 24.5.0 | `~/.volta/tools/image/node/24.5.0/bin/node` | Volta | mise では管理していない。pnpm・yarn なども Volta 経由 |
| Python 3.13.0 | `~/.local/share/mise/shims/python3` | mise（`~/.tool-versions`） | Homebrew の `python@3.13`（3.13.18）も入っているが、mise のほうが先に見つかる |
| Go 1.27.3 | `/opt/homebrew/bin/go` | Homebrew（`go`） | mise では管理していない |
| Java（OpenJDK 25.0.2） | `~/.local/share/mise/installs/java/openjdk-25/bin/java` | mise（`~/.config/mise/config.toml`） | Homebrew の `openjdk` も入っている |
| mise 本体 | `/opt/homebrew/bin/mise` | Homebrew（`mise`） | |

`home.nix` の `programs.mise.globalConfig` で、`~/.config/mise/config.toml` に次のバージョンを固定しています。

- `java = "openjdk-25"`（もとの `~/.config/mise/config.toml` と同じ）
- `python = "3.13.0"`（もとの `~/.tool-versions` と同じ）
- `go = "1.27.3"`（いま Homebrew で使っているものと同じ）

適用後の注意:

- 既存の `~/.config/mise/config.toml` は `config.toml.hm-backup` として退避されます。
- Go は mise にまだ入っていないので、適用後に `mise install` を実行してください。実行するまでは今までどおり Homebrew の go が使われます。
- `~/.tool-versions` の `python 3.13.0` は `config.toml` と内容が重なります。動作を確認したら削除して構いません。

### 提案: Homebrew の go と python@3.13 の削除（未実施）

mise が Go と Python を用意できるようになったら、Homebrew 側の重複は不要になります。この変更ではまだ削除していません。次の手順を提案します。

1. 適用後に `mise install` を実行し、`which go python3` が `~/.local/share/mise` 配下を指すことを確認する。
2. `brew uses --installed go python@3.13` で、他のフォーミュラの依存になっていないことを確認する（2026-11 時点では依存なし）。
3. `homebrew.nix` の `brews` から `"go"` と `"python@3.13"` を消し、`brew uninstall go python@3.13` を実行する（`onActivation.cleanup = "none"` なので、リストから消しただけではアンインストールされません）。

Node.js も Volta から mise に寄せることはできますが、Volta で入れたグローバルツール（pnpm、yarn、firebase など）の入れ直しが要るため、別の作業として扱います。

## 適用方法

ビルドだけ試す場合（システムは変更されません）:

```sh
cd /etc/nix-darwin
nix flake check
darwin-rebuild build --flake .#shuya-aarch64-darwin
```

実際に適用する場合:

```sh
sudo darwin-rebuild switch --flake /etc/nix-darwin#shuya-aarch64-darwin
```

## 初めて home-manager を適用するときの注意

- 既存の `~/.zshrc`、`~/.zprofile`、`~/.zshenv`、`~/.ssh/config` は、上書きされずに `*.hm-backup` という名前で退避されます（例: `~/.zshrc.hm-backup`）。同名の `*.hm-backup` が既にあると適用に失敗するので、先に消すか移動してください。
- 適用前に、`~/.ssh/config` の RunPod の `Host runpod` ブロックを `~/.ssh/config.local` にコピーしてください（適用後に `~/.ssh/config.hm-backup` からコピーしても構いません）。
- home-manager は git の設定を `~/.config/git/config` に書きます。`~/.gitconfig` が残っているとそちらも読まれるので、内容が同じことを確認したら `~/.gitconfig` を削除してください。
- `~/.zshrc` で `/opt/homebrew/bin` を PATH の先頭に追加しているため、Homebrew 版が残っている間は Nix 版より Homebrew 版が優先されます。Nix に移した CLI ツールは、適用後に `brew uninstall fzf gh ghq git neovim vim sheldon starship zoxide tree tenv sqlite ffmpeg watchman` で Homebrew 側から削除してください（他のフォーミュラの依存になっているものは残ります）。

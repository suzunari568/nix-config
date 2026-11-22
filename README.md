# nix設定

Apple Silicon の Mac（ユーザー `shuya`、ホスト設定 `shuya-aarch64-darwin`）を nix-darwin + home-manager + Homebrew で管理する設定です。
通常は `/etc/nix-darwin` に clone して使います。

## 何をどこで管理しているか

| 対象 | 管理先 | ファイル |
| --- | --- | --- |
| macOS の設定（Dock、Finder、スクリーンショット） | nix-darwin | `flake.nix`（`darwinModules.base`） |
| Nix 本体の設定 | Determinate Nix モジュール | `flake.nix`（`darwinModules.determinateNixConfig`） |
| `~/.zshenv`・`~/.zprofile`・`~/.zshrc` | home-manager（`programs.zsh`） | `home.nix` |
| git の設定（`~/.config/git/config`） | home-manager（`programs.git`） | `home.nix` |
| `~/.ssh/config` | home-manager（`programs.ssh`） | `home.nix` |
| CLI ツール（fzf, gh, ghq, git, neovim, vim, sheldon, starship, zoxide, tree, tenv, sqlite, ffmpeg, watchman） | home-manager（`home.packages`） | `home.nix` |
| GUI アプリ（cask）、tap、Mac App Store アプリ、VS Code 拡張 | nix-darwin の `homebrew` モジュール | `homebrew.nix` |
| Homebrew に残すフォーミュラ（go, python@3.13, openjdk, mise, libpq, mas, docker-compose, runpodctl） | nix-darwin の `homebrew` モジュール | `homebrew.nix` |
| 言語ランタイム（Node, Python, Go など） | mise（Nix では管理しない） | `~/.config/mise` |

補足:

- SSH の秘密鍵など、`~/.ssh/config` 以外のファイルは管理しません。
- 公開リポジトリに載せたくないホスト（RunPod など）は、管理対象外の `~/.ssh/config.local` に書きます。`~/.ssh/config` が `Include config.local` で読み込みます。
- sheldon・neovim・mise などの各ツール自体の設定（`~/.config/sheldon` など）は、これまでどおり手で管理します。
- `homebrew.onActivation` は `cleanup = "none"`、`autoUpdate = false`、`upgrade = false` にしています。適用しても Homebrew のアプリがアンインストールやアップグレードされることはありません。

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

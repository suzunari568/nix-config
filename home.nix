# home-manager configuration for the user "shuya".
# Reproduces the dotfiles that existed before home-manager took over
# (~/.zshenv, ~/.zprofile, ~/.zshrc, git config, ~/.ssh/config).
{
  config,
  pkgs,
  lib,
  ...
}:
{
  home.stateVersion = "26.05";

  # CLI tools moved from Homebrew formulas to Nix.
  # Language runtimes (Node, Python, Go, ...) stay in mise.
  home.packages = with pkgs; [
    ffmpeg
    fzf
    gh
    ghq
    neovim
    sheldon
    sqlite
    starship
    tenv
    tree
    vim
    watchman
    zoxide

    # Proposed dev tools (SAM-7). Kept in a separate commit so it can be dropped.
    bat # cat with syntax highlighting
    delta # git diff pager (not wired into git config; see README)
    eza # modern ls
    fd # fast find
    gh-dash # TUI dashboard for GitHub PRs and issues
    lazygit # git TUI
    ripgrep # fast grep (rg)
    shellcheck # shell script linter
    uv # Python package/project manager (Python itself stays on mise)
  ];

  # direnv + nix-direnv: per-directory env / `use flake` with caching.
  # Adds the `direnv hook zsh` line to ~/.zshrc.
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    enableZshIntegration = true;
  };

  # ---------------------------------------------------------------
  # zsh (~/.zshenv, ~/.zprofile, ~/.zshrc)
  # ---------------------------------------------------------------
  programs.zsh = {
    enable = true;
    # The original ~/.zshrc only runs compinit inside the Docker block below.
    enableCompletion = false;

    # ~/.zshenv
    envExtra = ''
      # volta configuration
      export VOLTA_HOME="$HOME/.volta"
      export PATH="$VOLTA_HOME/bin:$PATH"

      # pyenv configuration
      export PYENV_ROOT="$HOME/.pyenv"
      if command -v pyenv > /dev/null; then
       eval "$(pyenv init --path)"
       eval "$(pyenv init -)"
      fi
    '';

    # ~/.zprofile
    profileExtra = ''
      eval "$(/opt/homebrew/bin/brew shellenv)"
    '';

    # ~/.zshrc
    initContent = ''
      # -------------------------------------------------------------------
      # General Settings
      # -------------------------------------------------------------------
      export EDITOR='nvim'
      export VISUAL='nvim'

      export PATH="/opt/homebrew/bin:$PATH"

      eval "$(mise activate zsh)"

      # -------------------------------------------------------------------
      # Google Cloud SDK
      # -------------------------------------------------------------------
      export PATH="/opt/homebrew/share/google-cloud-sdk/bin:$PATH"

      # -------------------------------------------------------------------
      # Codex CLI (ChatGPT.app 同梱)
      # -------------------------------------------------------------------
      export PATH="/Applications/ChatGPT.app/Contents/Resources/codex-cli/CodexCLI.app/Contents/MacOS:$PATH"

      # -------------------------------------------------------------------
      # Dockerの入力補完
      # -------------------------------------------------------------------
      # ターミナルで docker と打って Tab を押したときに候補を出す設定
      if [ -d "$HOME/.docker/completions" ]; then
        fpath=("$HOME/.docker/completions" $fpath)
        autoload -Uz compinit && compinit
      fi

      # -------------------------------------------------------------------
      # Sheldon(プラグイン管理ツール)
      # -------------------------------------------------------------------
      if command -v sheldon > /dev/null; then
        eval "$(sheldon source)"
      fi

      # -------------------------------------------------------------------
      # Android SDK
      # -------------------------------------------------------------------
      export ANDROID_HOME="$HOME/Library/Android/sdk"
      export ANDROID_SDK_ROOT="$ANDROID_HOME"
      export PATH="$ANDROID_HOME/emulator:$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"
    '';
  };

  # ---------------------------------------------------------------
  # mise (~/.config/mise/config.toml only)
  # ---------------------------------------------------------------
  # mise itself stays in Homebrew and is activated in initContent above,
  # so no package and no shell integration come from Nix here.
  # Versions are pinned to what was in use when this was written.
  programs.mise = {
    enable = true;
    package = null;
    enableBashIntegration = false;
    enableFishIntegration = false;
    enableNushellIntegration = false;
    enableZshIntegration = false;
    globalConfig.tools = {
      java = "openjdk-25"; # was already in ~/.config/mise/config.toml
      python = "3.13.0"; # was in ~/.tool-versions
      go = "1.27.3"; # currently from Homebrew `go`; run `mise install go` after switching
    };
  };

  # ---------------------------------------------------------------
  # git (written to ~/.config/git/config)
  # ---------------------------------------------------------------
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "shuya";
        email = "76416677+suzunari568@users.noreply.github.com";
      };
      credential.helper = "osxkeychain";
      ghq.root = "${config.home.homeDirectory}/src";
    };
  };

  # ---------------------------------------------------------------
  # ssh (~/.ssh/config only; keys are never managed here)
  # ---------------------------------------------------------------
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    # Hosts that should not be published in this public repository
    # (e.g. the RunPod host) live in the unmanaged ~/.ssh/config.local.
    includes = [ "config.local" ];
    settings."github.com" = {
      HostName = "github.com";
      User = "git";
      IdentityFile = "~/.ssh/id_ed25519";
    };
  };
}

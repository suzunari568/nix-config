# nix-darwin homebrew module: GUI apps (casks), Mac App Store apps, and the
# formulas that intentionally stay in Homebrew.
# Applying this never uninstalls or upgrades anything (see onActivation).
{ ... }:
{
  homebrew = {
    enable = true;

    onActivation = {
      cleanup = "none";
      autoUpdate = false;
      upgrade = false;
    };

    taps = [
      {
        name = "runpod/runpodctl";
        trusted = true;
      }
      {
        name = "stablyai/orca";
        trusted = true;
      }
      {
        name = "yksr-melt/meltype";
        clone_target = "https://github.com/yksr-melt/Meltype.git";
      }
    ];

    # Formulas kept in Homebrew (everything else moved to home.packages).
    brews = [
      "docker-compose" # used together with Docker Desktop
      "go" # language runtime: not moved to Nix
      "libpq" # keg-only; projects may reference /opt/homebrew/opt/libpq
      "mas" # needed for masApps
      "mise" # language runtime manager: kept as is
      "openjdk" # language runtime (Android Studio / Java tooling)
      "python@3.13" # language runtime: not moved to Nix
      "runpod/runpodctl/runpodctl"
    ];

    casks = [
      "adobe-acrobat-reader"
      "android-studio"
      "anki"
      "antigravity"
      "brave-browser"
      "chatgpt"
      "claude"
      "clipy"
      "cursor"
      "discord"
      "docker-desktop"
      "drawio"
      "figma"
      "font-hack-nerd-font"
      "font-jetbrains-mono-nerd-font"
      "gcloud-cli"
      "google-chrome"
      "google-drive"
      "google-japanese-ime"
      "grok-bot"
      "keycastr"
      "yksr-melt/meltype/meltype"
      "notion"
      "obs"
      "obsidian"
      "stablyai/orca/orca"
      "postman"
      "rectangle"
      "scroll-reverser"
      "spotify"
      "tableplus"
      "visual-studio-code"
      "wezterm"
    ];

    masApps = {
      "GarageBand" = 682658836;
      "iMovie" = 408981434;
      "Keynote" = 409183694;
      "Kindle" = 302584613;
      "LINE" = 539883307;
      "Microsoft Excel" = 462058435;
      "Numbers" = 409203825;
      "Pages" = 409201541;
      "Whisper Transcription" = 1668083311;
      "Xcode" = 497799835;
    };

    vscode = [
      "anthropic.claude-code"
      "bierner.markdown-mermaid"
      "docker.docker"
      "ecmel.vscode-html-css"
      "esbenp.prettier-vscode"
      "github.codespaces"
      "golang.go"
      "marp-team.marp-vscode"
      "ms-azuretools.vscode-containers"
      "ms-azuretools.vscode-docker"
      "ms-python.debugpy"
      "ms-python.python"
      "ms-python.vscode-pylance"
      "ms-python.vscode-python-envs"
      "ms-vscode-remote.remote-containers"
      "openai.chatgpt"
      "openai.codex-audio"
      "redhat.java"
      "redhat.vscode-yaml"
      "vmware.vscode-boot-dev-pack"
      "vmware.vscode-spring-boot"
      "vscjava.vscode-gradle"
      "vscjava.vscode-java-debug"
      "vscjava.vscode-java-dependency"
      "vscjava.vscode-java-pack"
      "vscjava.vscode-java-test"
      "vscjava.vscode-maven"
      "vscjava.vscode-spring-boot-dashboard"
      "vscjava.vscode-spring-initializr"
      "vscodevim.vim"
    ];
  };
}

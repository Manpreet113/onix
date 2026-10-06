{ config, lib, pkgs, ... }: {
  programs.vscode = {
    enable = true;
    package = pkgs.vscode;
    # Use new HM profile API (2025+)
    profiles.default = {
      enableUpdateCheck = false;
      enableExtensionUpdateCheck = false;
      extensions = with pkgs.vscode-extensions; [
        # General
        vscodevim.vim
        ms-vscode-remote.remote-ssh
        github.copilot
        github.copilot-chat

        # Nix
        jnoortheen.nix-ide
        mkhl.direnv

        # JS/TS
        bradlc.vscode-tailwindcss
        esbenp.prettier-vscode
        dbaeumer.vscode-eslint

        # Python
        ms-python.python
        ms-python.vscode-pylance

        # Rust/Go
        rust-lang.rust-analyzer
        golang.go

        # Theme
        pkief.material-icon-theme
        enkia.tokyo-night
        dracula-theme.theme-dracula
      ];

      userSettings = {
        "editor.fontFamily" = "'JetBrainsMono Nerd Font', 'Droid Sans Mono', monospace";
        "editor.fontSize" = 13;
        "editor.fontLigatures" = true;
        "editor.formatOnSave" = true;
        "editor.defaultFormatter" = "esbenp.prettier-vscode";
        "editor.minimap.enabled" = false;
        "editor.rulers" = [80 120];
        "editor.tabSize" = 2;
        "editor.wordWrap" = "off";
        "editor.bracketPairColorization.enabled" = true;

        "workbench.colorTheme" = "Tokyo Night";
        "workbench.iconTheme" = "material-icon-theme";
        "workbench.startupEditor" = "none";

        "files.autoSave" = "onFocusChange";
        "files.trimTrailingWhitespace" = true;
        "files.insertFinalNewline" = true;

        "terminal.integrated.fontFamily" = "'JetBrainsMono Nerd Font'";
        "terminal.integrated.defaultProfile.linux" = "fish";
        "terminal.integrated.fontSize" = 12;

        "nix.enableLanguageServer" = true;
        "nix.serverPath" = "nixd";
        "nix.serverSettings.nixd.formatting.command" = ["alejandra"];
        "nix.hiddenLanguageServerErrors" = ["textDocument/completion"];

        "git.autofetch" = true;
        "git.confirmSync" = false;
        "git.enableSmartCommit" = true;

        "telemetry.telemetryLevel" = "off";
      };

      keybindings = [
        {
          key = "ctrl+shift+t";
          command = "workbench.action.terminal.new";
        }
      ];
    };
  };
}

{pkgs, ...}: {
  programs.fish = {
    enable = true;
    # Use fish as interactive shell with best UX
    shellAbbrs = {
      g = "git";
      gs = "git status";
      gc = "git commit";
      gp = "git push";
      gl = "git log --oneline --graph --decorate";
      nrs = "nh os switch";
      nrb = "nh os boot";
      nrt = "nh os test";
      nfu = "nix flake update";
      nfc = "nix flake check";
      ll = "eza -l --icons --git";
      la = "eza -la --icons --git";
      lt = "eza --tree --level=3 --icons";
      cat = "bat";
      grep = "rg";
      find = "fd";
    };
    shellAliases = {
      l = "eza -l --icons --git";
      ls = "eza --icons";
    };
    functions = {
      # quick mkcd
      mkcd = "mkdir -p $argv[1]; and cd $argv[1]";
      # yazi wrapper if needed
    };
    interactiveShellInit = ''
      set -g fish_greeting
      # Vi mode optional — keep emacs for now
      # fish_vi_key_bindings

      # Hydro-style prompt via starship, so no tide needed
      # fzf key bindings added via programs.fzf
      # zoxide init handled by programs.zoxide
    '';
    plugins = with pkgs.fishPlugins; [
      # Keep plugins minimal — tide conflicts with starship, so skip tide
      # Add useful plugins
      {
        name = "autopair";
        inherit (autopair) src;
      }
      {
        name = "puffer";
        inherit (puffer) src;
      }
      {
        name = "fzf-fish";
        inherit (fzf-fish) src;
      }
    ];
  };

  programs.fzf = {
    enable = true;
    enableFishIntegration = true;
    # Atuin owns Ctrl-R; fzf keeps Ctrl-T / Alt-C
    historyWidget.fish.command = "";
    defaultCommand = "fd --type f --hidden --follow --exclude .git";
    defaultOptions = ["--height 40%" "--border" "--preview 'bat --color=always {}'"];
  };

  programs.zoxide = {
    enable = true;
    enableFishIntegration = true;
    options = ["--cmd cd"];
  };

  programs.eza = {
    enable = true;
    enableFishIntegration = true;
    git = true;
    icons = "auto";
  };

  programs.bat = {
    enable = true;
    config = {
      style = "numbers,changes,header";
    };
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    silent = false;
  };

  programs.atuin = {
    enable = true;
    enableFishIntegration = true;
    flags = ["--disable-up-arrow"];
    settings = {
      auto_sync = false;
      search_mode = "fuzzy";
      inline_height = 20;
      style = "compact";
    };
  };

  programs.ripgrep.enable = true;
  programs.fd.enable = true;
  programs.jq.enable = true;

  # Carapace completions
  programs.carapace = {
    enable = true;
    enableFishIntegration = true;
  };

  # Ensure fish completions work for nix
  programs.nix-index.enableFishIntegration = true;
}

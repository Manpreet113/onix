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

      # Tide lean prompt (static colors until skein grows a tide template,
      # then a guarded source like the ones below). Configured once via
      # sentinel so user tweaks survive; delete the sentinel to re-run.
      if not test -f ~/.local/share/onix-shell/tide-lean-configured
        tide configure --auto --style=Lean --prompt_colors='True color' --show_time='24-hour format' --prompt_spacing=Compact --icons='Many icons' --transient=Yes
        and mkdir -p ~/.local/share/onix-shell
        and touch ~/.local/share/onix-shell/tide-lean-configured
      end

      # fzf key bindings added via programs.fzf
      # zoxide init handled by programs.zoxide

      # Live wallpaper-driven colors (skein renders these on every theme
      # change; guarded so a fresh boot without the daemon still works)
      if test -f ~/.cache/skein/fish-theme.fish
        source ~/.cache/skein/fish-theme.fish
      end
      if test -f ~/.cache/skein/fzf.fish
        source ~/.cache/skein/fzf.fish
      end
    '';
    plugins = with pkgs.fishPlugins; [
      {
        name = "tide";
        inherit (tide) src;
      }
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

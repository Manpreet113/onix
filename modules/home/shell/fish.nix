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

      # Tide lean prompt + transient. Applied once via sentinel so user
      # tweeks survive; delete the sentinel to re-apply. (tide v6's
      # `configure --auto` can't do this non-interactively, so we apply
      # the lean preset the same way the wizard's finish step does:
      # every line becomes a universal var, then `tide reload`.)
      if not test -f ~/.local/share/onix-shell/tide-lean-configured
        set -g _tide_color_dark_blue 0087AF
        set -g _tide_color_dark_green 5FAF00
        set -g _tide_color_gold D7AF00
        set -g _tide_color_green 5FD700
        set -g _tide_color_light_blue 00AFFF
        # NOTE: plain `set -l` would die with the for-block (fish scoping),
        # so the preset path rides a uniquely-named global instead.
        set -g _onix_tide_preset ""
        for d in $fish_function_path
          if test -f $d/tide/configure/configs/lean.fish
            set -g _onix_tide_preset $d/tide/configure/configs/lean.fish
            break
          end
        end
        if test -n "$_onix_tide_preset"
          for v in (set -U -n)
            string match -q "_tide*" -- $v; and set -eU $v
            string match -q "tide_*" -- $v; and set -eU $v
          end
          for line in (cat $_onix_tide_preset | string match -v -r '^\s*(#|$)')
            set -l parts (string split -m1 ' ' -- "$line")
            # single-string eval: multi-arg eval does not join-then-run
            set -l cmd "set -U $parts[1] $parts[2]"
            eval $cmd
          end
          set -U tide_prompt_transient_enabled false
          tide reload >/dev/null 2>&1
          mkdir -p ~/.local/share/onix-shell
          touch ~/.local/share/onix-shell/tide-lean-configured
        end
        set -e _onix_tide_preset
        set -e _tide_color_dark_blue _tide_color_dark_green _tide_color_gold _tide_color_green _tide_color_light_blue
      end

      # fzf key bindings added via programs.fzf
      # zoxide init handled by programs.zoxide

      # Live wallpaper-driven colors (skein renders these on every theme
      # change; guarded so a fresh boot without the daemon still works).
      # tide-theme.fish re-sets universal color vars, so it stays fresh.
      if test -f ~/.cache/skein/fish-theme.fish
        source ~/.cache/skein/fish-theme.fish
      end
      if test -f ~/.cache/skein/fzf.fish
        source ~/.cache/skein/fzf.fish
      end
      if test -f ~/.cache/skein/tide-theme.fish
        source ~/.cache/skein/tide-theme.fish
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

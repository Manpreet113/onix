{
  config,
  lib,
  pkgs,
  ...
}: {
  programs.git = {
    enable = true;
    lfs.enable = true;

    settings = {
      user = {
        name = "Manpreet113";
        email = "manpreet10542@gmail.com";
      };
      init.defaultBranch = "main";
      pull.rebase = true;
      push.autoSetupRemote = true;
      fetch.prune = true;
      rerere.enabled = true;
      core = {
        editor = "nvim";
        autocrlf = "input";
        whitespace = "trailing-space,space-before-tab";
      };
      diff.colorMoved = "zebra";
      merge.conflictStyle = "zdiff3";
      rebase.autoStash = true;
      commit.verbose = true;
      help.autocorrect = "prompt";
      column.ui = "auto";
      branch.sort = "-committerdate";
      tag.sort = "version:refname";
      alias = {
        st = "status";
        ci = "commit";
        co = "checkout";
        br = "branch";
        unstage = "reset HEAD --";
        last = "log -1 HEAD";
        visual = "!gitk";
        lg = "log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit";
        amend = "commit --amend";
        undo = "reset HEAD~1 --mixed";
        pr = "pull --rebase";
        sync = "!git pull --rebase && git push";
      };
    };

    ignores = [
      ".direnv/"
      "result"
      "result-*"
      ".envrc.local"
    ];
  };

  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options = {
      navigate = true;
      light = false;
      side-by-side = false;
      line-numbers = true;
      syntax-theme = "TwoDark";
      features = "decorations";
      decorations = {
        commit-decoration-style = "bold yellow box ul";
        file-style = "bold yellow ul";
        file-decoration-style = "none";
        hunk-header-decoration-style = "cyan box ul";
      };
    };
  };

  programs.gh = {
    enable = true;
    settings = {
      git_protocol = "https";
    };
  };

  programs.lazygit.enable = true;
}

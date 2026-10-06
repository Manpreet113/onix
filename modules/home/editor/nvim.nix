{ config, lib, pkgs, ... }: {
  programs.neovim = {
    enable = true;
    package = pkgs.neovim-unwrapped;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;
    withNodeJs = true;
    withPython3 = true;

    plugins = with pkgs.vimPlugins; [
      # Core
      nvim-treesitter.withAllGrammars
      telescope-nvim
      telescope-fzf-native-nvim
      nvim-lspconfig
      nvim-cmp
      cmp-nvim-lsp
      cmp-buffer
      cmp-path
      luasnip
      friendly-snippets
      lualine-nvim
      gitsigns-nvim
      which-key-nvim
      comment-nvim
      nvim-autopairs
      indent-blankline-nvim
      tokyonight-nvim
      gruvbox-nvim
      telescope-file-browser-nvim
      plenary-nvim
      nvim-web-devicons
      oil-nvim
    ];

    extraPackages = with pkgs; [
      ripgrep
      fd
      nil
      nixd
      nixfmt
      lua-language-server
      typescript-language-server
      pyright
      rust-analyzer
    ];

    initLua = ''
      vim.opt.number = true
      vim.opt.relativenumber = true
      vim.opt.termguicolors = true
      vim.opt.expandtab = true
      vim.opt.shiftwidth = 2
      vim.opt.tabstop = 2
      vim.opt.smartindent = true
      vim.opt.wrap = false
      vim.opt.scrolloff = 8
      vim.opt.signcolumn = "yes"
      vim.opt.colorcolumn = "80"
      vim.opt.clipboard = "unnamedplus"
      vim.g.mapleader = " "
      vim.g.maplocalleader = " "

      -- Colorscheme
      pcall(function() vim.cmd.colorscheme("tokyonight-night") end)

      -- Lualine
      pcall(function() require('lualine').setup { options = { theme = 'tokyonight' } } end)

      -- Treesitter (handled via HM, minimal setup)
      -- LSP will be configured per-language via nvim-lspconfig
    '';
  };

  # Ensure nvim is default editor
  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
  };

  # Also expose nano removal note: nothing to do, just not installed
}

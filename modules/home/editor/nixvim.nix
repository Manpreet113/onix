_: {
  programs.nixvim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;

    globals = {
      mapleader = " ";
      maplocalleader = " ";
    };

    opts = {
      number = true;
      relativenumber = true;
      termguicolors = true;
      expandtab = true;
      shiftwidth = 2;
      tabstop = 2;
      smartindent = true;
      wrap = false;
      scrolloff = 8;
      signcolumn = "yes";
      colorcolumn = "80";
      clipboard = "unnamedplus";
    };

    # Live wallpaper-driven colorscheme: skein deploys skein.lua into
    # colors/ on every theme change (see services.skein deploy targets).
    # pcall so a fresh boot without the daemon still opens cleanly.
    colorschemes.nord.enable = false;
    extraConfigLua = ''
      pcall(vim.cmd, "colorscheme skein")
    '';

    plugins = {
      web-devicons.enable = true;

      treesitter.enable = true;

      telescope = {
        enable = true;
        extensions.fzf-native.enable = true;
        keymaps = {
          "<leader>ff" = "find_files";
          "<leader>fg" = "live_grep";
          "<leader>fb" = "buffers";
          "<leader>fh" = "help_tags";
          "<leader>fr" = "oldfiles";
        };
      };

      oil.enable = true;
      lualine.enable = true;
      gitsigns.enable = true;
      which-key.enable = true;
      comment.enable = true;
      nvim-autopairs.enable = true;
      indent-blankline.enable = true;

      luasnip.enable = true;
      friendly-snippets.enable = true;

      cmp = {
        enable = true;
        autoEnableSources = true;
        settings = {
          sources = [
            {name = "nvim_lsp";}
            {name = "luasnip";}
            {name = "path";}
            {name = "buffer";}
          ];
          snippet.expand = ''
            function(args)
              require("luasnip").lsp_expand(args.body)
            end
          '';
          mapping.__raw = ''
            cmp.mapping.preset.insert({
              ["<C-Space>"] = cmp.mapping.complete(),
              ["<CR>"] = cmp.mapping.confirm({ select = true }),
              ["<Tab>"] = cmp.mapping.select_next_item(),
              ["<S-Tab>"] = cmp.mapping.select_prev_item(),
            })
          '';
        };
      };

      lsp = {
        enable = true;
        servers = {
          nixd.enable = true;
          lua_ls.enable = true;
          ts_ls.enable = true;
          pyright.enable = true;
          rust_analyzer = {
            enable = true;
            installCargo = false;
            installRustc = false;
          };
        };
        keymaps = {
          silent = true;
          lspBuf = {
            gd = "definition";
            gD = "declaration";
            gi = "implementation";
            gr = "references";
            K = "hover";
            "<leader>rn" = "rename";
            "<leader>ca" = "code_action";
            "<leader>fm" = "format";
          };
          diagnostic = {
            "[d" = "goto_prev";
            "]d" = "goto_next";
            "<leader>dd" = "open_float";
          };
        };
      };
    };

    keymaps = [
      {
        mode = "n";
        key = "-";
        action = "<cmd>Oil<CR>";
        options = {
          desc = "Open parent directory (oil)";
          silent = true;
        };
      }
      {
        mode = "n";
        key = "<leader>e";
        action = "<cmd>Oil<CR>";
        options = {
          desc = "File explorer (oil)";
          silent = true;
        };
      }
      {
        mode = "n";
        key = "<Esc>";
        action = "<cmd>nohlsearch<CR>";
        options.silent = true;
      }
      {
        mode = "n";
        key = "<C-h>";
        action = "<C-w>h";
        options.silent = true;
      }
      {
        mode = "n";
        key = "<C-j>";
        action = "<C-w>j";
        options.silent = true;
      }
      {
        mode = "n";
        key = "<C-k>";
        action = "<C-w>k";
        options.silent = true;
      }
      {
        mode = "n";
        key = "<C-l>";
        action = "<C-w>l";
        options.silent = true;
      }
    ];
  };
}

return {
  {
    "bjarneo/aether.nvim",
    branch = "v3",
    name = "aether",
    priority = 1000,
    opts = {
      colors = {
        bg         = "#020200",
        dark_bg    = "#020200",
        darker_bg  = "#010100",
        lighter_bg = "#1b1b1a",

        fg         = "#e7d9bb",
        dark_fg    = "#ada38c",
        light_fg   = "#ebdfc5",
        bright_fg  = "#ede3cc",
        muted      = "#42433f",

        red        = "#8c3900",
        yellow     = "#6f7113",
        orange     = "#9d5726",
        green      = "#5c6e00",
        cyan       = "#5f7105",
        blue       = "#923e00",
        purple     = "#964100",
        brown      = "#5e3417",

        bright_red    = "#c25300",
        bright_yellow = "#898e00",
        bright_green  = "#748c00",
        bright_cyan   = "#799000",
        bright_blue   = "#bc5900",
        bright_purple = "#b85b00",

        accent               = "#923e00",
        cursor               = "#e7d9bb",
        foreground           = "#e7d9bb",
        background           = "#020200",
        selection             = "#1b1b1a",
        selection_foreground = "#e7d9bb",
        selection_background = "#1b1b1a",
      },
    },
    -- set up hot reload
    config = function(_, opts)
      require("aether").setup(opts)
      vim.cmd.colorscheme("aether")
      require("aether.hotreload").setup()
    end,
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "aether",
    },
  },
}

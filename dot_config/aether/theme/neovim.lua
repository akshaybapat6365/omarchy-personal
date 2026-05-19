return {
  {
    "bjarneo/aether.nvim",
    branch = "v3",
    name = "aether",
    priority = 1000,
    opts = {
      colors = {
        bg         = "#030400",
        dark_bg    = "#020300",
        darker_bg  = "#020200",
        lighter_bg = "#1c1d1a",

        fg         = "#eee4cf",
        dark_fg    = "#b3ab9b",
        light_fg   = "#f1e8d6",
        bright_fg  = "#f2ebdb",
        muted      = "#63645e",

        red        = "#d05500",
        yellow     = "#a6a91c",
        orange     = "#d76f26",
        green      = "#88a300",
        cyan       = "#8fa908",
        blue       = "#d75c00",
        purple     = "#db5f00",
        brown      = "#814317",

        bright_red    = "#ff760f",
        bright_yellow = "#cbd200",
        bright_green  = "#aacd00",
        bright_cyan   = "#b1d300",
        bright_blue   = "#ff7d08",
        bright_purple = "#ff8105",

        accent               = "#d75c00",
        cursor               = "#eee4cf",
        foreground           = "#eee4cf",
        background           = "#030400",
        selection             = "#1c1d1a",
        selection_foreground = "#eee4cf",
        selection_background = "#1c1d1a",
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

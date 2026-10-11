-- Tiling geometry. Border colors come from modules.colors.
local colors = require("modules.colors")

hl.config({
  general = {
    gaps_in = 8,
    gaps_out = 12,
    border_size = 2,
    col = {
      active_border = colors.active_border,
      inactive_border = colors.inactive_border,
    },
    layout = "dwindle",
  },
})

-- Tiling geometry. Border colors come from modules.colors.
local colors = require("modules.colors")

hl.general({
  ["border_size"] = 2,
  ["col.active_border"] = colors.active_border,
  ["col.inactive_border"] = colors.inactive_border,
  ["gaps_in"] = 8,
  ["gaps_out"] = 12,
  ["layout"] = "dwindle",
})

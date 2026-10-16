-- Onix shell layer rules: blur + animation policy per namespace.
-- Namespaces match `WlrLayershell.namespace` in qs. Check live with
-- `hyprctl layers`.
hl.layer_rule({
  name = "onix-bar-blur",
  match = { namespace = "^onix-bar$" },
  blur = true,
  ignore_alpha = 0.2,
})

hl.layer_rule({
  name = "onix-sheets-blur",
  match = { namespace = "^(onix-control|onix-notif-center|onix-powermenu|onix-settings)$" },
  blur = true,
  blur_popups = true,
  ignore_alpha = 0.28,
  dim_around = true,
})

hl.layer_rule({
  name = "onix-overlay-noanim",
  match = { namespace = "^(onix-notifs|onix-osd|onix-frame|onix-wallpaper|onix-picker|onix-launcher|onix-edge|onix-spotlight)$" },
  no_anim = true,
  ignore_alpha = 0.0,
})

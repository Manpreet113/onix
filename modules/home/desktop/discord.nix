_: {
  programs.nixcord = {
    enable = true;
    discord.vencord.enable = true;

    # Live wallpaper-driven colors: skein renders colors.css on every theme
    # change and Vencord resolves the @import at runtime. Missing file at
    # first boot is a silent no-op (default Discord theme underneath).
    quickCss = ''
      @import url("file:///home/manpreet/.cache/skein/colors.css");
      :root {
        --background-primary: var(--skein-background);
        --background-secondary: var(--skein-surface);
        --background-tertiary: var(--skein-surface-variant);
        --background-floating: var(--skein-surface);
        --channeltextarea-background: var(--skein-surface);
        --text-normal: var(--skein-text);
        --text-muted: var(--skein-subtext);
        --header-primary: var(--skein-text);
        --header-secondary: var(--skein-subtext);
        --text-link: var(--skein-accent);
        --brand-500: var(--skein-primary);
        --brand-560: var(--skein-accent);
        --red-400: var(--skein-error);
        --green-360: var(--skein-success);
        --yellow-300: var(--skein-warning);
      }
    '';
    config = {
      useQuickCss = true;
      frameless = true;
    };
  };
}

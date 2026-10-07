_: {
  programs.wofi = {
    enable = true;
    settings = {
      width = 600;
      height = 400;
      location = "center";
      allow_images = true;
      allow_markup = true;
      prompt = "Search...";
      insensitive = true;
      no_actions = true;
    };
  };
}

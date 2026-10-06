{ config, lib, pkgs, ... }: {
  programs.wofi = {
    enable = true;
    style = ''
      window {
        margin: 0px;
        border: 2px solid #458588;
        border-radius: 8px;
        background-color: #282828;
      }
      #input {
        margin: 5px;
        border: none;
        color: #ebdbb2;
        background-color: #3c3836;
      }
      #inner-box {
        margin: 5px;
        border: none;
        background-color: #282828;
      }
      #outer-box {
        margin: 5px;
        border: none;
        background-color: #282828;
      }
      #scroll {
        margin: 0px;
        border: none;
      }
      #text {
        margin: 5px;
        border: none;
        color: #ebdbb2;
      }
      #entry:selected {
        background-color: #458588;
      }
      #text:selected {
        color: #fbf1c7;
      }
    '';
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

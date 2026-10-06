{
  description = "onix - modular NixOS flake for host onix";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    import-tree.url = "github:vic/import-tree";

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-flatpak.url = "github:gmodena/nix-flatpak/?ref=latest";

    opencode = {
      url = "github:anomalyco/opencode";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix = {
      url = "github:nix-community/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {flake-parts, ...}:
    flake-parts.lib.mkFlake {inherit inputs;} {
      imports = [
      ];

      systems = ["x86_64-linux"];

      perSystem = {
        config,
        pkgs,
        ...
      }: {
        formatter = pkgs.alejandra;

        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            alejandra
            nixd
            nil
            nix-output-monitor
            nh
            git
            sops
            age
          ];
          shellHook = ''
            echo "onix devShell — nh, nom, alejandra ready"
          '';
        };
      };

      flake = {
        nixosConfigurations = {
          onix = inputs.nixpkgs.lib.nixosSystem {
            system = "x86_64-linux";
            specialArgs = {inherit inputs;};
            modules = [
              ./hosts/onix
              ./hosts/common
              inputs.home-manager.nixosModules.home-manager
              inputs.sops-nix.nixosModules.sops
              inputs.disko.nixosModules.disko
              inputs.nix-flatpak.nixosModules.nix-flatpak
              inputs.stylix.nixosModules.stylix
              {
                home-manager = {
                  useGlobalPkgs = true;
                  useUserPackages = true;
                  backupFileExtension = "hm-backup";
                  extraSpecialArgs = {inherit inputs;};
                  users.manpreet = import ./homes/manpreet.nix;
                };
              }
            ];
          };
        };
      };
    };
}

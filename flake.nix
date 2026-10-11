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

    opencode = {
      url = "github:anomalyco/opencode";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixcord = {
      url = "github:4evy/nixcord";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    skein = {
      url = "github:manpreet113/skein";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {flake-parts, ...}:
    flake-parts.lib.mkFlake {inherit inputs;} {
      imports = [
      ];

      systems = ["x86_64-linux"];

      perSystem = {pkgs, ...}: {
        formatter = pkgs.writeShellApplication {
          name = "onix-fmt";
          runtimeInputs = [pkgs.alejandra];
          text = "alejandra .";
        };

        checks.statix = pkgs.runCommand "statix-check" {nativeBuildInputs = [pkgs.statix];} ''
          cd ${./.}
          statix check .
          touch $out
        '';

        checks.deadnix = pkgs.runCommand "deadnix-check" {nativeBuildInputs = [pkgs.deadnix];} ''
          cd ${./.}
          deadnix --fail .
          touch $out
        '';

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
            statix
            deadnix
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

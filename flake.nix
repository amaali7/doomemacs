{
  description = "Declarative Doom Emacs configuration as a Nix flake (modules you can extend)";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    home-manager.url = "github:nix-community/home-manager/release-26.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      ...
    }:
    let
      inherit (nixpkgs) lib;
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems = lib.genAttrs systems;
      pkgsFor = system: nixpkgs.legacyPackages.${system};

      evalDoom =
        {
          system,
          modules ? [ ],
        }:
        let
          pkgs = pkgsFor system;
        in
        lib.evalModules {
          modules = [
            { _module.args = { inherit pkgs; }; }
            ./modules/options.nix
            ./modules/defaults.nix
            ./modules/features/ui.nix
            ./modules/features/editor.nix
            ./modules/features/lsp.nix
            ./modules/features/org.nix
            ./modules/features/cursor.nix
            { doomemacs.enable = true; }
          ]
          ++ modules;
        };

      mkDoomDir =
        {
          system,
          modules ? [ ],
        }:
        import ./lib/mk-doom-dir.nix {
          pkgs = pkgsFor system;
          inherit lib;
          cfg = (evalDoom { inherit system modules; }).config.doomemacs;
          staticDir = ./doom;
        };
    in
    {
      lib = import ./lib { inherit lib; } // {
        inherit evalDoom mkDoomDir;
      };

      homeModules.default = ./modules/home-manager.nix;
      homeModules.doomemacs = self.homeModules.default;
      homeManagerModules.default = self.homeModules.default;
      homeManagerModules.doomemacs = self.homeModules.default;

      nixosModules.default = ./modules/nixos.nix;
      nixosModules.doomemacs = self.nixosModules.default;

      overlays.default = final: prev: {
        doomemacsConfig = self.packages.${final.stdenv.hostPlatform.system}.doomDir;
      };

      packages = forAllSystems (system: rec {
        doomDir = mkDoomDir { inherit system; };
        default = doomDir;
      });

      formatter = forAllSystems (system: (pkgsFor system).nixfmt);

      devShells = forAllSystems (
        system:
        let
          pkgs = pkgsFor system;
        in
        {
          default = pkgs.mkShell {
            packages = [
              pkgs.nixfmt
              pkgs.nixd
              pkgs.git
            ];
          };
        }
      );

      checks = forAllSystems (system: {
        doomDir = self.packages.${system}.doomDir;
      });

      templates.default = {
        path = ./examples;
        description = "Example Home Manager snippet that extends this Doom Emacs flake";
      };
    };
}

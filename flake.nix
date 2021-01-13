{
  description = "My personal website and blog";

  inputs = {
    nixpkgs.url = github:NixOS/nixpkgs/nixpkgs-unstable;
    flake-utils.url = github:numtide/flake-utils;
    hakyll-src = {
      url = github:jaspervdj/hakyll;
      flake = false;
    };
  };

  outputs = { self, nixpkgs, flake-utils, hakyll-src }: flake-utils.lib.eachDefaultSystem (system:
    let
      out = import ./nix/default.nix { inherit system nixpkgs; };
      pkgs = import nixpkgs {
        inherit system;
        overlays = [
          (import ./overlay.nix { inherit hakyll-src; } [ "ghc8102" ])
        ];
      };
      hpkgs = pkgs.haskell.packages.ghc8102;
    in {
      packages = rec {
        inherit (hpkgs) site;
        blog = pkgs.stdenv.mkDerivation {
          name = "blog";
          src = pkgs.nix-gitignore.gitignoreSource [] ./.;
          buildPhase = "${site}/bin/site build";
          installPhase = ''cp -r _site "$out"'';
        };
      };
      defaultPackage = self.packages.${system}.blog;
      devShell = hpkgs.shellFor {
        packages = _: [ self.packages.${system}.site ];
        exactDeps = true;
        buildInputs = with hpkgs; [ ghcid cabal-install ];
      };
    }
  );
}

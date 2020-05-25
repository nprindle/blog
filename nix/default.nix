let
  sources = import ./sources.nix;

  pkgs = import sources.nixpkgs {
    overlays = [ (import ./overlay.nix) ];
  };

  hpkgs = pkgs.haskell.packages.ghc883;

  clean = import ./clean.nix { inherit (pkgs) lib; };
in

rec {
  inherit (hpkgs) site;

  blog = pkgs.stdenv.mkDerivation {
    name = "blog";
    src = clean ../.;

    buildPhase = "${site}/bin/site build";
    installPhase = ''cp -r _site "$out"'';
  };
}

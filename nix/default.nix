let
  sources = import ./sources.nix;

  pkgs = import sources.nixpkgs {
    overlays = [ (import ./overlay.nix) ];
  };

  hpkgs = pkgs.haskell.packages.ghc883;
in

rec {
  # The executable to build the site
  inherit (hpkgs) site;

  # The site itself
  blog = pkgs.stdenv.mkDerivation {
    name = "site";
    src = pkgs.lib.cleanSource ../.;
    buildPhase = "${site}/bin/site build";
    installPhase = ''cp -r _site "$out"'';
  };

  shell = hpkgs.shellFor {
    packages = ps: with ps; [ site ];

    buildInputs = (with pkgs; [
      # Needed for niv
      niv nix cacert
    ]) ++ (with hpkgs; [
      ghcid
      cabal-install
      stylish-haskell
    ]);

    withHoogle = true;
    exactDeps = true;
  };
}

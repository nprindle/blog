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

    # Need to set this for Unicode support
    LOCALE_ARCHIVE = "${pkgs.glibcLocales}/lib/locale/locale-archive";
    LANG = "en_US.UTF-8";

    buildPhase = "${site}/bin/site build";
    installPhase = ''cp -r _site "$out"'';
  };

  shell = hpkgs.shellFor {
    packages = [ site ];

    buildInputs = (with pkgs; [
      # Needed for niv
      niv nix cacert
    ]) ++ (with hpkgs; [
      ghcid
    ]);

    # Unicode support
    LOCALE_ARCHIVE = "${pkgs.glibcLocales}/lib/locale/locale-archive";
    shellHook = ''
      export LANG=en_US.UTF-8
    '';
  };
}

self: super:

let
  sources = import ./sources.nix;

  inherit (super) lib;
  hlib = super.haskell.lib;
  clean = import ./clean.nix { inherit (super) lib; };

  ghcOverride = input: ovl: input.override (old: {
    overrides = lib.composeExtensions (old.overrides or (_: _: {})) ovl;
  });

  # Package overrides
  packageOverlay = hself: hsuper: {
    pandoc-citeproc = hsuper.callCabal2nix "pandoc-citeproc" (super.fetchFromGitHub {
      owner = "jgm";
      repo = "pandoc-citeproc";
      rev = "a4a11ec91098ee355aa04cfdb00ec40dc4435c4f";
      sha256 = "1dx540bdl2y2fmfygj6r5zl33hra2dlkr6kac9qf0y8rymwl97i3";
    }) {};

    hakyll =
      let
        pkg = hsuper.callCabal2nix "hakyll" (super.fetchFromGitHub {
          owner = "jaspervdj";
          repo = "hakyll";
          rev = "e97ea3afcc1779fd1a9967d8c175cdd33e0311bc";
          sha256 = "0k1vikxdyq0npllr9jazv5k9g4hr1xik36c82n4cb2wvx7gbldhk";
        }) {};
        confFlags = [ "-f" "watchServer" "-f" "previewServer" ];
      in hlib.appendConfigureFlags pkg confFlags;
  };

  # Result packages
  mainOverlay = hself: hsuper: {
    site = hsuper.callCabal2nix "blog" (clean ../.) {};
  };

  composeOverlays = lib.foldl' lib.composeExtensions (_: _: {});

in {
  niv = import sources.niv {};

  haskell = super.haskell // {
    packages = super.haskell.packages // {
      ghc883 = ghcOverride super.haskell.packages.ghc883
        (composeOverlays [ mainOverlay packageOverlay ]);
    };
  };
}

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
    hakyll =
      let confFlags = [ "-f" "watchServer" "-f" "previewServer" ];
      in hlib.appendConfigureFlags hsuper.hakyll confFlags;
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

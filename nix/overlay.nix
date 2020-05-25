self: super:

let
  sources = import ./sources.nix;

  inherit (super) lib;
  hlib = super.haskell.lib;
  clean = import ./clean.nix { inherit (super) lib; };

  ghcOverride = input: ovl: input.override (old: {
    overrides = lib.composeExtensions (old.overrides or (_: _: {})) ovl;
  });

  haskellOverlay = hself: hsuper: {
    # TODO
  };

in {
  niv = import sources.niv {};

  haskell = super.haskell // {
    packages = super.haskell.packages // {
      ghc8101 = ghcOverride super.haskell.packages.ghc8101 haskellOverlay;
    };
  };
}

self: super:

let
  sources = import ./sources.nix;

  inherit (super) lib;
  hlib = super.haskell.lib;
  clean = import ./clean.nix { inherit (super) lib; };

  ghcOverride = input: ovl: input.override (old: {
    overrides = lib.composeExtensions (old.overrides or (_: _: {})) ovl;
  });

  fixGhcWithHoogle = input: ghcOverride input (hself: hsuper: {
    # Compose the selector with a null filter to fix error on null packages
    ghcWithHoogle = selector:
      hsuper.ghcWithHoogle (ps: builtins.filter (x: x != null) (selector ps));
    ghc = hsuper.ghc // { withHoogle = hself.ghcWithHoogle; };
  });

  # Package overrides
  packageOverlay = hself: hsuper: {
    hakyll =
      let confFlags = [ "-f" "watchServer" "-f" "previewServer" ];
      in hlib.appendConfigureFlags hsuper.hakyll confFlags;
  };

  # Result packages
  mainOverlay = hself: hsuper: {
    site = (hsuper.callCabal2nix "blog" (clean ../.) {}).overrideAttrs (old: {
      nativeBuildInputs = (old.nativeBuildInputs or []) ++ [ super.makeWrapper ];
      # Need to set $LANG for Unicode support in a pure environment
      postInstall = (old.postInstall or "") + ''
        wrapProgram "$out/bin/site" \
          --set LOCALE_ARCHIVE "${super.glibcLocales}/lib/locale/locale-archive" \
          --set LANG "en_US.UTF-8"
      '';
    });
  };

  composeOverlays = lib.foldl' lib.composeExtensions (_: _: {});

in {
  niv = (import sources.niv {}).niv;

  haskell = super.haskell // {
    packages = super.haskell.packages // {
      ghc883 = fixGhcWithHoogle (ghcOverride super.haskell.packages.ghc883
        (composeOverlays [ mainOverlay packageOverlay ]));
    };
  };
}

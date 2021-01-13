{ hakyll-src }:

ghcs:

self: super:

let
  inherit (super) lib;
  hlib = super.haskell.lib;
  clean = super.nix-gitignore.gitignoreSource ''
    /**.rst
    /**.html
    /**.css
    /**.markdown
    /**.png
    /**.jpg
  '';

  ghcOverlay = input: ovl: input.override (old: {
    overrides = lib.composeExtensions (old.overrides or (_: _: {})) ovl;
  });

  fixGhcWithHoogle = input: ghcOverlay input (hself: hsuper: {
    # Compose the selector with a null filter to fix error on null packages
    ghcWithHoogle = selector:
      hsuper.ghcWithHoogle (ps: builtins.filter (x: x != null) (selector ps));
    ghc = hsuper.ghc // { withHoogle = hself.ghcWithHoogle; };
  });

  haskellOverlay = hself: hsuper: {
    hakyll =
      let
        pkg = hsuper.callCabal2nix "hakyll" hakyll-src {};
        confFlags = [ "-f" "watchServer" "-f" "previewServer" ];
      in hlib.appendConfigureFlags pkg confFlags;

    site =
      let
        pkg = hsuper.callCabal2nix "site" (clean ./.) {};
      in pkg.overrideAttrs (old: {
        nativeBuildInputs = (old.nativeBuildInputs or []) ++ [ super.makeWrapper ];
        # Need to set $LANG for Unicode support in a pure environment
        postInstall = (old.postInstall or "") + ''
          wrapProgram "$out/bin/site" \
            --set LOCALE_ARCHIVE "${super.glibcLocales}/lib/locale/locale-archive" \
            --set LANG "en_US.UTF-8"
        '';
      });
  };

  overrideGHCs = ghcs: lib.listToAttrs (builtins.map (ghc: {
    name = ghc;
    value = fixGhcWithHoogle (ghcOverlay super.haskell.packages.${ghc} haskellOverlay);
  }) ghcs);
in {
  haskell = super.haskell // {
    packages = super.haskell.packages // overrideGHCs ghcs;
  };
}

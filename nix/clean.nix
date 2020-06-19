{ lib }:

path:

if !lib.canCleanSource path
then path
else lib.cleanSourceWith {
  src = lib.cleanSource path;
  filter = name: type:
    let
      baseName = baseNameOf (toString name);
      # Filetypes to ignore, e.g. ".nix"
      ignoreExts = [
        # These are only ignored when building the executable
        ".markdown" ".md" ".rst" ".html" ".css" ".png" ".jpg" ".jpeg"
      ];
    in !lib.any (x: x) [
      ((type == "regular") && (lib.any (ext: lib.hasSuffix ext baseName) ignoreExts))
      # git files
      ((type == "directory") && (baseName == ".git"))
      ((type == "regular") && (baseName == ".gitignore"))
      # ghc output
      ((type == "directory") && (baseName == "dist" || baseName == "dist-newtype"))
      ((type == "regular") && (lib.hasPrefix ".ghc" baseName))
      # hakyll output
      ((type == "directory") && (baseName == "_site" || baseName == "_cache"))
    ];
}


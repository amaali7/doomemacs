{
  pkgs,
  lib,
  cfg,
  staticDir,
}:

let
  elisp = import ./elisp.nix { inherit lib; };

  pkgName = p: if builtins.isString p then p else p.name;
  kept = lib.filter (p: !(lib.elem (pkgName p) (cfg.disablePackages or [ ])));

  initEl = elisp.mkInitEl {
    modules = cfg.finalModules;
    extraInit = cfg.extraInit or "";
    beforeMarker = cfg.extraInitBefore or "";
  };

  packagesEl =
    elisp.mkPackagesEl {
      packages = kept (cfg.packages or [ ]);
      extraPackages = kept (cfg.extraPackages or [ ]);
      unpin = (cfg.unpin or [ ]) ++ (cfg.extraUnpin or [ ]);
      beforeMarker = cfg.extraPackagesBefore or "";
    }
    + (cfg.extraPackagesEl or "");

  writeRel = name: text: pkgs.writeTextDir name text;

  sanitize = name: lib.replaceStrings [ "/" " " "+" ] [ "-" "-" "plus-" ] name;

  copyRel =
    name: value:
    pkgs.runCommand "doom-${sanitize name}" { } ''
      mkdir -p "$out/$(dirname ${lib.escapeShellArg name})"
      cp -r ${value} "$out/${name}"
    '';

  extraFilePaths = lib.mapAttrsToList (
    name: value:
    if builtins.isPath value || lib.isDerivation value then copyRel name value else writeRel name value
  ) (cfg.extraFiles or { });

  lispFiles = lib.mapAttrsToList writeRel (cfg.generatedLisp or { });

  static = pkgs.runCommand "doom-static-assets" { } ''
    mkdir -p "$out/themes" "$out/snippets/rustic-mode"
    cp ${staticDir + "/themes/noctalia-theme.el"} "$out/themes/noctalia-theme.el"
    cp ${staticDir + "/snippets/rustic-mode/+reg.yasnippet"} \
       "$out/snippets/rustic-mode/+reg.yasnippet"
  '';
in
pkgs.runCommand "doom-private-config" { } ''
  set -e
  mkdir -p $out/doom $out/doom/themes $out/doom/snippets/rustic-mode

  # Main config files (config.el is generated in ~/.config/doom by the
  # Home Manager activation script; see modules/home-manager.nix)
  cp ${pkgs.writeTextDir "init.el" initEl}/init.el $out/doom/init.el
  cp ${pkgs.writeTextDir "packages.el" packagesEl}/packages.el $out/doom/packages.el

  # Generated lisp files (+*.el, ...) - flat in DOOMDIR so `(load! "+foo")`
  # resolves relative to the user's config.el
  ${lib.concatMapStringsSep "\n" (f: "cp -r ${f}/* $out/doom/") lispFiles}

  # Copy extra files
  ${lib.concatMapStringsSep "\n" (p: "cp -r ${p}/* $out/doom/") extraFilePaths}

  # Static assets
  cp ${static}/themes/*.el $out/doom/themes/
  cp ${static}/snippets/rustic-mode/* $out/doom/snippets/rustic-mode/
''

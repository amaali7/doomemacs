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

  loadNames =
    let
      names = builtins.attrNames (cfg.generatedLisp or { });
      plusFiles = builtins.filter (n: lib.hasPrefix "+" n) names;
      stems = map (n: lib.removePrefix "+" (lib.removeSuffix ".el" n)) plusFiles;
      order =
        cfg.featureLoadOrder or [
          "ui"
          "editor"
          "lsp"
          "org"
          "cursor"
        ];
      ordered = lib.filter (s: lib.elem s stems) order;
      rest = lib.subtractLists ordered stems;
    in
    map (s: "+" + s) (ordered ++ rest) ++ (cfg.extraLispLoads or [ ]);

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

  configEl = elisp.mkConfigEl {
    loads = loadNames;
    extraConfigEarly = cfg.extraConfigEarly or "";
    extraConfig = cfg.extraConfig or "";
    beforeMarker = cfg.extraConfigBefore or "";
  };

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
  mkdir -p $out/doom/+ $out/doom/themes $out/doom/snippets/rustic-mode

  # Main config files
  cp ${pkgs.writeTextDir "init.el" initEl}/init.el $out/doom/init.el
  cp ${pkgs.writeTextDir "packages.el" packagesEl}/packages.el $out/doom/packages.el
  cp ${pkgs.writeTextDir "config.el" configEl}/config.el $out/doom/config.el

  # Feature files (+*.el) - go into doom/+ subdirectory for load! macro
  ${lib.concatMapStringsSep "\n" (f: "cp -r ${f}/* $out/doom/+/" ) lispFiles}

  # Copy extra files
  ${lib.concatMapStringsSep "\n" (p: "cp -r ${p}/* $out/doom/" ) extraFilePaths}

  # Static assets
  cp ${static}/themes/*.el $out/doom/themes/
  cp ${static}/snippets/rustic-mode/* $out/doom/snippets/rustic-mode/
''

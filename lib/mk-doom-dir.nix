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
  };

  packagesEl =
    elisp.mkPackagesEl {
      packages = kept (cfg.packages or [ ]);
      extraPackages = kept (cfg.extraPackages or [ ]);
      unpin = (cfg.unpin or [ ]) ++ (cfg.extraUnpin or [ ]);
    }
    + (cfg.extraPackagesEl or "");

  configEl = elisp.mkConfigEl {
    loads = loadNames;
    extraConfigEarly = cfg.extraConfigEarly or "";
    extraConfig = cfg.extraConfig or "";
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
pkgs.symlinkJoin {
  name = "doom-private-config";
  paths = [
    (writeRel "init.el" initEl)
    (writeRel "packages.el" packagesEl)
    (writeRel "config.el" configEl)
    static
  ]
  ++ lispFiles
  ++ extraFilePaths;
}

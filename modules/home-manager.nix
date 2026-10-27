{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.doomemacs;

  # Names of generated `+*.el` files to `load!` from the user's config.el,
  # in `featureLoadOrder`, followed by `extraLispLoads`.
  loadNames =
    let
      names = builtins.attrNames cfg.generatedLisp;
      plusFiles = builtins.filter (n: lib.hasPrefix "+" n) names;
      stems = map (n: lib.removePrefix "+" (lib.removeSuffix ".el" n)) plusFiles;
      ordered = lib.filter (s: lib.elem s stems) cfg.featureLoadOrder;
      rest = lib.subtractLists ordered stems;
    in
    map (s: "+" + s) (ordered ++ rest) ++ cfg.extraLispLoads;

  loadsEl = lib.concatMapStringsSep "\n" (name: "(load! \"${name}\")") loadNames;

  # Elisp written into the managed block of the user's config.el, before
  # the @@USER_CODE@@ markers.
  managedEl = lib.concatStringsSep "\n" (
    lib.filter (s: s != "") [
      cfg.extraConfigEarly
      (cfg.extraConfigBefore or "")
      loadsEl
      cfg.extraConfig
    ]
  );

  langEnabled = name: (cfg.finalModules.lang.${name}.enable or false);

  langTools =
    with pkgs;
    lib.optionals (langEnabled "rust") [ rust-analyzer ]
    ++ lib.optionals (langEnabled "nix") [
      nixd
      nixfmt-rfc-style
    ]
    ++ lib.optionals (langEnabled "javascript") [ typescript-language-server ]
    ++ lib.optionals (langEnabled "json") [ vscode-langservers-extracted ]
    ++ lib.optionals (langEnabled "yaml") [ yaml-language-server ]
    ++ lib.optionals (langEnabled "lua") [ lua-language-server ]
    ++ lib.optionals (langEnabled "sh") [
      bash-language-server
      shellcheck
      shfmt
    ]
    ++ lib.optionals (langEnabled "web") [ vscode-langservers-extracted ]
    ++ lib.optionals (langEnabled "markdown") [
      marksman
      markdownlint-cli2
      pandoc
    ]
    ++ lib.optionals (langEnabled "plantuml") [ plantuml ]
    ++ lib.optionals (langEnabled "graphviz") [ graphviz ]
    ++ lib.optionals (langEnabled "python") [ pyright ];

  baseTools = with pkgs; [
    git
    ripgrep
    fd
    ispell
    editorconfig-core-c
  ];

  fonts = with pkgs; [
    jetbrains-mono
    fira-code
    fira-sans
  ];
in
{
  imports = [
    ./options.nix
    ./defaults.nix
    ./features/ui.nix
    ./features/editor.nix
    ./features/lsp.nix
    ./features/org.nix
    ./features/cursor.nix
    ./features/gptel.nix
  ];

  config = lib.mkMerge [
    {
      doomemacs.finalDoomDir = import ../lib/mk-doom-dir.nix {
        inherit pkgs lib;
        cfg = builtins.removeAttrs config.doomemacs [ "finalDoomDir" ];
        staticDir = ../doom;
      };
    }
    (lib.mkIf cfg.enable {
      home.packages =
        (lib.optional cfg.installEmacs cfg.finalEmacsPackage)
        ++ baseTools
        ++ fonts
        ++ langTools
        ++ cfg.extraBinPackages;

      fonts.fontconfig.enable = lib.mkDefault true;

      home.sessionPath = [ "$HOME/.config/emacs/bin" ];

      home.sessionVariables.DOOMDIR = "${config.xdg.configHome}/${cfg.doomDir}";

      # Activation hook to install doom config into ~/.config/doom
      # config.el is generated in place: a managed block (load! lines + Nix
      # extraConfig) plus user code preserved between the @@USER_CODE@@ markers.
      home.activation.installDoomConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        set -e
        doom_config="${cfg.finalDoomDir}"
        doom_dir="$HOME/.config/doom"
        user_marker_start=";; @@USER_CODE_START@@"
        user_marker_end=";; @@USER_CODE_END@@"

        mkdir -p "$doom_dir"

        # Shell-quoted managed elisp: load! lines for generated +*.el files
        # plus extraConfigEarly / extraConfigBefore / extraConfig
        doom_managed=${lib.escapeShellArg managedEl}

        # Rebuild config.el, preserving user code between the markers
        install_config() {
          local dst=$1
          local user_code=""
          if [ -f "$dst" ] && grep -q "$user_marker_start" "$dst" 2>/dev/null; then
            # Extract existing user code between markers (dropping old boilerplate)
            user_code=$(
              awk -v s="$user_marker_start" -v e="$user_marker_end" '$0 ~ s, $0 ~ e' "$dst" |
                sed '1d;$d' |
                grep -v -F -x \
                  -e ';; Add your custom doom config below - preserved across regenerations' \
                  -e ';; Examples:' \
                  -e ';;   (setq doom-font (font-spec :family "JetBrains Mono" :size 14))' \
                  -e ';;   (setq company-idle-delay 0.1)' 2>/dev/null || true
            )
          fi
          {
            echo ';; Managed by the doomemacs Nix flake - regenerated on every switch.'
            echo ';; Only code between the @@USER_CODE@@ markers is yours to edit.'
            echo ""
            if [ -n "$doom_managed" ]; then
              printf '%s\n' "$doom_managed"
              echo ""
            fi
            echo "$user_marker_start"
            echo ';; Add your custom doom config below - preserved across regenerations'
            if [ -n "$user_code" ]; then
              echo "$user_code"
            fi
            echo "$user_marker_end"
          } > "$dst"
          chmod 644 "$dst"
        }

        # Generate config.el in place: managed load! block + preserved user code
        install_config "$doom_dir/config.el"

        # Copy init.el and packages.el from the store
        if [ -f "''${doom_config}/doom/init.el" ]; then
          cp -f "''${doom_config}/doom/init.el" "$doom_dir/init.el"
          chmod 644 "$doom_dir/init.el"
        fi
        if [ -f "''${doom_config}/doom/packages.el" ]; then
          cp -f "''${doom_config}/doom/packages.el" "$doom_dir/packages.el"
          chmod 644 "$doom_dir/packages.el"
        fi

        # Copy generated lisp files (+*.el, ...) loaded by the managed block above
        for f in "$doom_config/doom/"*.el; do
          [ -e "$f" ] || continue
          base=$(basename "$f")
          case "$base" in
            init.el | packages.el) continue ;;
          esac
          cp -f "$f" "$doom_dir/$base"
          chmod 644 "$doom_dir/$base"
        done

        # Copy themes and snippets
        if [ -d "''${doom_config}/doom/themes" ]; then
          mkdir -p "$doom_dir/themes"
          cp -f "''${doom_config}/doom/themes/"*.el "$doom_dir/themes/" 2>/dev/null || true
          chmod 644 "$doom_dir/themes/"*.el 2>/dev/null || true
        fi
        if [ -d "''${doom_config}/doom/snippets" ]; then
          mkdir -p "$doom_dir/snippets"
          cp -rf "''${doom_config}/doom/snippets/"* "$doom_dir/snippets/" 2>/dev/null || true
          chmod -R 644 "$doom_dir/snippets/" 2>/dev/null || true
        fi

        echo "doomemacs: installed config to $doom_dir"
      '';

      home.activation.installDoomEmacs = lib.mkIf cfg.installDoom (
        lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          doom_src="$HOME/.config/emacs"
          if [ ! -f "$doom_src/early-init.el" ]; then
            echo "doomemacs: cloning Doom Emacs into $doom_src"
            ${pkgs.git}/bin/git clone --depth 1 ${lib.escapeShellArg cfg.doomEmacsRepo} "$doom_src"
          fi
        ''
      );
    })
  ];
}

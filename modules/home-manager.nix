{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.doomemacs;

  langEnabled = name: (cfg.finalModules.lang.${name}.enable or false);

  langTools =
    with pkgs;
    lib.optionals (langEnabled "rust") [ rust-analyzer ]
    ++ lib.optionals (langEnabled "nix") [
      nixd
      nixfmt
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
      xdg.configFile.${cfg.doomDir} = {
        source = cfg.finalDoomDir;
        recursive = true;
      };

      home.packages =
        (lib.optional cfg.installEmacs cfg.finalEmacsPackage)
        ++ baseTools
        ++ fonts
        ++ langTools
        ++ cfg.extraBinPackages;

      fonts.fontconfig.enable = lib.mkDefault true;

      home.sessionPath = [ "$HOME/.config/emacs/bin" ];

      home.sessionVariables.DOOMDIR = "${config.xdg.configHome}/${cfg.doomDir}";

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

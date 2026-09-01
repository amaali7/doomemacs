{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib)
    mkEnableOption
    mkOption
    types
    literalExpression
    ;

  doomModule = types.submodule {
    options = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = "Whether to emit this Doom module in `init.el`.";
      };
      flags = mkOption {
        type = types.listOf types.str;
        default = [ ];
        example = [
          "lsp"
          "tree-sitter"
        ];
        description = "Doom module flags, without the leading `+`.";
      };
      when = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "(featurep :system 'macos)";
        description = "Optional Elisp condition wrapping `(:if COND module)`.";
      };
    };
  };

  doomPackage = types.submodule {
    options = {
      name = mkOption {
        type = types.str;
        description = "Package name as used by Doom's `package!` macro.";
      };
      recipe = mkOption {
        type = types.nullOr (
          types.submodule {
            options = {
              host = mkOption {
                type = types.nullOr types.str;
                default = "github";
                description = "Straight recipe `:host`.";
              };
              repo = mkOption {
                type = types.nullOr types.str;
                default = null;
                description = "Straight recipe `:repo` (`user/repo`).";
              };
              branch = mkOption {
                type = types.nullOr types.str;
                default = null;
              };
              pin = mkOption {
                type = types.nullOr types.str;
                default = null;
              };
              files = mkOption {
                type = types.listOf types.str;
                default = [ ];
              };
              extra = mkOption {
                type = types.lines;
                default = "";
                description = "Raw extra keywords inside `:recipe (...)`.";
              };
            };
          }
        );
        default = null;
        description = "Optional Straight.el recipe. Null for MELPA/ELPA.";
      };
    };
  };
in
{
  options.doomemacs = {
    enable = mkEnableOption "this Doom Emacs private configuration";

    emacsPackage = mkOption {
      type = types.nullOr types.package;
      default = null;
      defaultText = literalExpression "pkgs.emacs";
      description = "Emacs package to install. `null` uses `pkgs.emacs`.";
    };

    doomDir = mkOption {
      type = types.str;
      default = "doom";
      description = "Directory under `xdg.configHome` for the generated DOOMDIR.";
    };

    installEmacs = mkOption {
      type = types.bool;
      default = true;
      description = "Install Emacs via Home Manager / NixOS.";
    };

    installDoom = mkOption {
      type = types.bool;
      default = true;
      description = "Clone Doom Emacs into `~/.config/emacs` if missing.";
    };

    doomEmacsRepo = mkOption {
      type = types.str;
      default = "https://github.com/doomemacs/doomemacs.git";
    };

    features = {
      ui = mkEnableOption "UI feature file (`+ui.el`)" // {
        default = true;
      };
      editor = mkEnableOption "editor feature file (`+editor.el`)" // {
        default = true;
      };
      lsp = mkEnableOption "LSP feature file (`+lsp.el`)" // {
        default = true;
      };
      org = mkEnableOption "Org feature file (`+org.el`)" // {
        default = true;
      };
      cursor = mkEnableOption "Cursor IDE/CLI feature file (`+cursor.el`)" // {
        default = true;
      };
    };

    modules = mkOption {
      type = types.attrsOf (types.attrsOf doomModule);
      default = { };
      description = "Doom `init.el` modules, keyed by category then module name.";
    };

    extraModules = mkOption {
      type = types.attrsOf (types.attrsOf doomModule);
      default = { };
      description = "Merged into `modules` with `lib.recursiveUpdate` (extraModules wins).";
    };

    packages = mkOption {
      type = types.listOf doomPackage;
      default = [ ];
      description = "Entries written to `packages.el` via `package!`.";
    };

    extraPackages = mkOption {
      type = types.listOf doomPackage;
      default = [ ];
      description = "Appended after `packages`.";
    };

    unpin = mkOption {
      type = types.listOf types.str;
      default = [ "org-roam" ];
      description = "Package names passed to Doom's `unpin!` macro.";
    };

    extraBinPackages = mkOption {
      type = types.listOf types.package;
      default = [ ];
      description = "Extra programs on PATH for Emacs.";
    };

    recommendedTools = mkOption {
      type = types.bool;
      default = true;
      description = "Install ripgrep, fd, git, sqlite, fonts, and LSPs based on enabled modules.";
    };

    extraPackagesEl = mkOption {
      type = types.lines;
      default = "";
      description = "Raw elisp appended to packages.el.";
    };

    disablePackages = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Package names dropped from the generated packages.el.";
    };

    extraUnpin = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Additional names for `unpin!` (concatenated with `unpin`).";
    };

    emacsDaemon = mkOption {
      type = types.bool;
      default = false;
      description = "Enable the user systemd Emacs daemon.";
    };

    featureLoadOrder = mkOption {
      type = types.listOf types.str;
      default = [
        "ui"
        "editor"
        "lsp"
        "org"
        "cursor"
      ];
      description = "Order of generated `+feature` files in config.el.";
    };

    extraConfigEarly = mkOption {
      type = types.lines;
      default = "";
      description = "Elisp inserted at the top of `config.el`.";
    };

    extraConfig = mkOption {
      type = types.lines;
      default = "";
      description = "Elisp appended to `config.el` after feature loads.";
    };

    extraInit = mkOption {
      type = types.lines;
      default = "";
      description = "Elisp appended to `init.el` after `(doom! ...)`.";
    };

    generatedLisp = mkOption {
      type = types.attrsOf types.lines;
      default = { };
      description = "Extra `*.el` files in DOOMDIR. Keys starting with `+` are `load!`ed.";
    };

    extraFiles = mkOption {
      type = types.attrsOf (
        types.oneOf [
          types.str
          types.path
          types.package
        ]
      );
      default = { };
      description = "Additional files copied into DOOMDIR.";
    };

    extraLispLoads = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Extra `load!` names after generated feature files.";
    };

    ui = {
      theme = mkOption {
        type = types.str;
        default = "catppuccin";
      };
      font = {
        family = mkOption {
          type = types.str;
          default = "JetBrains Mono";
        };
        size = mkOption {
          type = types.number;
          default = 12.5;
        };
        weight = mkOption {
          type = types.nullOr types.str;
          default = "semi-light";
        };
      };
      variablePitchFont = {
        family = mkOption {
          type = types.str;
          default = "Fira Sans";
        };
        size = mkOption {
          type = types.number;
          default = 12.5;
        };
      };
      lineNumbers = mkOption {
        type = types.enum [
          "relative"
          "visual"
          "absolute"
          "none"
        ];
        default = "relative";
      };
      extraConfig = mkOption {
        type = types.lines;
        default = "";
      };
    };

    editor = {
      vtermShell = mkOption {
        type = types.nullOr types.str;
        default = null;
      };
      caseSensitiveSearch = mkOption {
        type = types.bool;
        default = true;
      };
      extraConfig = mkOption {
        type = types.lines;
        default = "";
      };
    };

    lsp = {
      disableSemgrep = mkOption {
        type = types.bool;
        default = true;
      };
      diagnosticsProvider = mkOption {
        type = types.enum [
          "flycheck"
          "flymake"
          "auto"
        ];
        default = "flycheck";
      };
      uiDoc = {
        enable = mkOption {
          type = types.bool;
          default = true;
        };
        delay = mkOption {
          type = types.number;
          default = 0.5;
        };
        maxWidth = mkOption {
          type = types.ints.positive;
          default = 100;
        };
      };
      extraConfig = mkOption {
        type = types.lines;
        default = "";
      };
    };

    org = {
      directory = mkOption {
        type = types.str;
        default = "~/org/";
      };
      babelLanguages = mkOption {
        type = types.listOf types.str;
        default = [
          "python"
          "shell"
        ];
      };
      roamUi = mkOption {
        type = types.bool;
        default = true;
      };
      extraConfig = mkOption {
        type = types.lines;
        default = "";
      };
    };

    cursor = {
      extraConfig = mkOption {
        type = types.lines;
        default = "";
      };
    };

    finalEmacsPackage = mkOption {
      type = types.package;
      visible = false;
      readOnly = true;
    };

    finalModules = mkOption {
      type = types.attrs;
      visible = false;
      readOnly = true;
    };

    finalDoomDir = mkOption {
      type = types.package;
      visible = false;
      readOnly = true;
    };
  };

  config.doomemacs.finalEmacsPackage =
    if config.doomemacs.emacsPackage != null then config.doomemacs.emacsPackage else pkgs.emacs;

  config.doomemacs.finalModules = lib.recursiveUpdate config.doomemacs.modules config.doomemacs.extraModules;
}

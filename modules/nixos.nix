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
    ++ lib.optionals (langEnabled "javascript") [
      (typescript-language-server or nodePackages.typescript-language-server)
    ]
    ++ lib.optionals (langEnabled "json") [ vscode-langservers-extracted ]
    ++ lib.optionals (langEnabled "yaml") [ yaml-language-server ]
    ++ lib.optionals (langEnabled "lua") [ lua-language-server ]
    ++ lib.optionals (langEnabled "sh") [
      bash-language-server
      shellcheck
      shfmt
    ]
    ++ lib.optionals (langEnabled "web") [ vscode-langservers-extracted ]
    ++ lib.optionals (langEnabled "python") [ pyright ]
    ++ lib.optionals (langEnabled "plantuml") [ plantuml ]
    ++ lib.optionals (langEnabled "graphviz") [ graphviz ];

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
  ];

  config = lib.mkIf cfg.enable {
    environment.systemPackages =
      (lib.optional cfg.installEmacs cfg.finalEmacsPackage)
      ++ (with pkgs; [
        git
        ripgrep
        fd
        ispell
        editorconfig-core-c
      ])
      ++ langTools
      ++ cfg.extraBinPackages;

    fonts.packages = fonts;
  };
}

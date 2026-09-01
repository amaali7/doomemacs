# Extend this Doom Emacs flake from another Home Manager config.
#
#   imports = [ inputs.doomemacs.homeModules.default ./extend.nix ];
#
{
  doomemacs = {
    enable = true;

    # Add a language Doom module without copying init.el.
    extraModules.lang.python = {
      enable = true;
      flags = [ "lsp" ];
    };

    # Extra straight/MELPA packages.
    extraPackages = [
      { name = "rainbow-delimiters"; }
      {
        name = "some-git-pkg";
        recipe = {
          host = "github";
          repo = "user/some-git-pkg";
        };
      }
    ];

    extraBinPackages = [ ]; # e.g. pkgs.ruff

    extraConfig = ''
      ;; Loaded at the end of config.el
      (setq confirm-kill-emacs nil)
    '';

    generatedLisp."+python.el" = ''
      ;;; +python.el -*- lexical-binding: t; -*-
      (after! python
        (setq python-indent-offset 4))
    '';

    extraFiles."snippets/python-mode/pdb" = ''
      # -*- mode: snippet -*-
      # name: pdb
      # key: pdb
      # --
      breakpoint()
    '';

    ui.theme = "catppuccin";
    ui.font.size = 13.0;
    org.directory = "~/org/";
  };
}

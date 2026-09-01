{ lib, ... }:

# Default Doom modules and packages matching ~/.dotfiles/doom (current private config).
{
  config.doomemacs = {
    modules = lib.mkDefault {
      completion = {
        company.enable = true;
        vertico.enable = true;
      };
      ui = {
        doom.enable = true;
        doom-dashboard.enable = true;
        emoji = {
          enable = true;
          flags = [ "unicode" ];
        };
        hl-todo.enable = true;
        indent-guides.enable = true;
        ligatures.enable = true;
        modeline.enable = true;
        nav-flash.enable = true;
        ophints.enable = true;
        popup = {
          enable = true;
          flags = [ "defaults" ];
        };
        unicode.enable = true;
        "vc-gutter" = {
          enable = true;
          flags = [ "pretty" ];
        };
        vi-tilde-fringe.enable = true;
        window-select.enable = true;
        workspaces.enable = true;
      };
      editor = {
        evil = {
          enable = true;
          flags = [ "everywhere" ];
        };
        file-templates.enable = true;
        fold.enable = true;
        format = {
          enable = true;
          flags = [ "onsave" ];
        };
        multiple-cursors.enable = true;
        snippets.enable = true;
      };
      emacs = {
        dired = {
          enable = true;
          flags = [
            "dirvish"
            "icons"
          ];
        };
        electric.enable = true;
        ibuffer.enable = true;
        undo.enable = true;
        vc.enable = true;
      };
      term = {
        vterm.enable = true;
      };
      checkers = {
        syntax.enable = true;
        spell = {
          enable = true;
          flags = [ "flyspell" ];
        };
        grammar.enable = true;
      };
      tools = {
        debugger = {
          enable = true;
          flags = [ "peek" ];
        };
        direnv.enable = true;
        eval = {
          enable = true;
          flags = [ "overlay" ];
        };
        lookup = {
          enable = true;
          flags = [ "bindings" ];
        };
        lsp = {
          enable = true;
          flags = [ "peek" ];
        };
        magit.enable = true;
        pass.enable = true;
        pdf.enable = true;
        tmux.enable = true;
        tree-sitter.enable = true;
      };
      os = {
        macos = {
          enable = true;
          when = "(featurep :system 'macos)";
        };
      };
      lang = {
        emacs-lisp.enable = true;
        json = {
          enable = true;
          flags = [
            "lsp"
            "tree-sitter"
          ];
        };
        javascript = {
          enable = true;
          flags = [
            "lsp"
            "tree-sitter"
          ];
        };
        lua.enable = true;
        markdown.enable = true;
        nix.enable = true;
        org = {
          enable = true;
          flags = [ "roam" ];
        };
        plantuml.enable = true;
        graphviz.enable = true;
        rest.enable = true;
        rust = {
          enable = true;
          flags = [
            "lsp"
            "tree-sitter"
          ];
        };
        sh.enable = true;
        web = {
          enable = true;
          flags = [ "lsp" ];
        };
        yaml.enable = true;
      };
      config = {
        default = {
          enable = true;
          flags = [
            "bindings"
            "smartparens"
          ];
        };
      };
    };

    packages = lib.mkDefault [
      { name = "catppuccin-theme"; }
      {
        name = "alabaster-themes";
        recipe = {
          host = "github";
          repo = "vedang/alabaster-themes";
        };
      }
      {
        name = "org-roam-ui";
        recipe = {
          host = "github";
          repo = "org-roam/org-roam-ui";
        };
      }
      {
        name = "el-easydraw";
        recipe = {
          host = "github";
          repo = "misohena/el-easydraw";
        };
      }
      {
        name = "nushell-mode";
        recipe = {
          host = "github";
          repo = "mrkkrp/nushell-mode";
        };
      }
      {
        name = "nushell-ts-mode";
        recipe = {
          host = "github";
          repo = "herbertjones/nushell-ts-mode";
        };
      }
      { name = "verb"; }
      { name = "javelin"; }
      {
        name = "cursor-agent";
        recipe = {
          host = "github";
          repo = "chocoelho/cursor-agent.el";
          files = [ "cursor-agent.el" ];
        };
      }
    ];
  };
}

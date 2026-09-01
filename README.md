# doomemacs

Declarative [Doom Emacs](https://github.com/doomemacs/doomemacs) private config
as a **Nix flake**. It encodes the current `~/.dotfiles/doom` setup (modules,
packages, UI, LSP, Org, Cursor) as **Nix modules** you can enable, override, and
extend without hand-editing generated Elisp.

Generated files land in `$XDG_CONFIG_HOME/doom` (usually `~/.config/doom`).
Doom itself still lives in `~/.config/emacs` and uses `straight.el`; after a
rebuild you run `doom sync` once when `init.el` / `packages.el` change.

| Piece | What it is |
|-------|------------|
| `nixosModules.default` | System Emacs, fonts, ripgrep/fd, language servers |
| `homeModules.default` | Generates DOOMDIR, installs Emacs + tools, optional Doom clone |
| `packages.doomDir` | The generated private config (buildable without Home Manager) |
| `lib.mkDoomDir` / `lib.evalDoom` | Evaluate or render the config from extra Nix modules |

Namespace for all options: **`doomemacs.*`**.

---

## Quick start

### Preview the generated DOOMDIR

```bash
cd ~/work/Nix/doomemacs
nix build .#doomDir
find result -type f | sort
```

### Home Manager (standalone)

```nix
# flake.nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-26.05";
    home-manager.url = "github:nix-community/home-manager/release-26.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    doomemacs.url = "git+file:///home/ai3wm/work/Nix/doomemacs";
    doomemacs.inputs.nixpkgs.follows = "nixpkgs";
    doomemacs.inputs.home-manager.follows = "home-manager";
  };

  outputs = { nixpkgs, home-manager, doomemacs, ... }: {
    homeConfigurations."ai3wm" = home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages.x86_64-linux;
      modules = [
        doomemacs.homeModules.default
        {
          home.username = "ai3wm";
          home.homeDirectory = "/home/ai3wm";
          home.stateVersion = "26.05";
          doomemacs.enable = true;
        }
      ];
    };
  };
}
```

Then:

```bash
home-manager switch --flake .#ai3wm
export PATH="$HOME/.config/emacs/bin:$PATH"
doom sync          # first time, or after module/package changes
emacs
```

### Snowfall / `~/work/Nix/nixos` (amaali7)

Add the input and attach the modules:

```nix
# flake.nix (inputs)
doomemacs.url = "git+file:///home/ai3wm/work/Nix/doomemacs";
doomemacs.inputs.nixpkgs.follows = "nixpkgs";
doomemacs.inputs.home-manager.follows = "home-manager";
```

```nix
# flake.nix (lib.mkFlake)
homes.modules = [
  inputs.doomemacs.homeModules.default
];
systems.modules.nixos = [
  inputs.doomemacs.nixosModules.default
];
```

Enable in a home module (replaces the old `ln -snf ~/.dotfiles/doom` activation):

```nix
# modules/home/apps/emacs/config/doom/default.nix
{ lib, ... }:
{
  doomemacs.enable = true;
}
```

Keep `amaali7.apps.emacs.enable = true` if you still want the wrapper; point it
at `doomemacs.enable` instead of the symlink. NixOS module installs fonts and
LSPs system-wide; Home Manager writes `~/.config/doom`.

---

## What is generated (maps to the old Doom files)

| Generated file | Source |
|----------------|--------|
| `init.el` | `doomemacs.modules` + `extraModules` |
| `packages.el` | `doomemacs.packages` + `extraPackages` + `unpin` |
| `config.el` | loads `+*.el`, then `extraConfig` |
| `+ui.el` | `doomemacs.features.ui` + `doomemacs.ui.*` |
| `+editor.el` | `doomemacs.features.editor` + `doomemacs.editor.*` |
| `+lsp.el` | `doomemacs.features.lsp` + `doomemacs.lsp.*` |
| `+org.el` | `doomemacs.features.org` + `doomemacs.org.*` |
| `+cursor.el` | `doomemacs.features.cursor` + `doomemacs.cursor.*` |
| `themes/noctalia-theme.el` | vendored from the current config |
| `snippets/rustic-mode/+reg.yasnippet` | vendored |

Do not edit files under `~/.config/doom` — they are store-backed. Change Nix
options and rebuild.

---

## Defaults (current private config)

Doom modules enabled out of the box:

- **completion:** company, vertico
- **ui:** doom, doom-dashboard, emoji+unicode, hl-todo, indent-guides, ligatures, modeline, nav-flash, ophints, popup+defaults, unicode, vc-gutter+pretty, vi-tilde-fringe, window-select, workspaces
- **editor:** evil+everywhere, file-templates, fold, format+onsave, multiple-cursors, snippets
- **emacs:** dired+dirvish+icons, electric, ibuffer, undo, vc
- **term:** vterm
- **checkers:** syntax (flycheck), spell+flyspell, grammar
- **tools:** debugger+peek, direnv, eval+overlay, lookup+bindings, lsp+peek, magit, pass, pdf, tmux, tree-sitter
- **lang:** emacs-lisp, json/javascript +lsp +tree-sitter, lua, markdown, nix, org+roam, plantuml, graphviz, rest, rust+lsp+tree-sitter, sh, web+lsp, yaml
- **config:** default+bindings+smartparens

Extra `package!` entries: catppuccin-theme, alabaster-themes, org-roam-ui,
el-easydraw, nushell-mode, nushell-ts-mode, verb, javelin, cursor-agent.

UI: JetBrains Mono 12.5 semi-light, Fira Sans 12.5, theme `catppuccin`, relative
line numbers.

Editor: bash for scripts, Nushell for vterm, case-sensitive buffer search,
Dirvish on `SPC -` / `SPC 5` / `SPC 6`, javelin `M-1`…`M-9`.

Cursor: `SPC c A` prefix (prompt, interactive, region, open in Cursor IDE, …).

---

## Extending

You almost never need to fork this flake. Import the Home Manager module and set
options in *your* config.

### 1. Add or disable Doom modules

```nix
doomemacs.extraModules = {
  lang.python = { enable = true; flags = [ "lsp" ]; };
  tools.docker.enable = true;
};

# Disable something from the defaults (leaf mkForce wins over mkDefault)
doomemacs.modules.ui.unicode.enable = lib.mkForce false;
```

`extraModules` is `lib.recursiveUpdate`d on top of `modules`. Flags are Doom
flags without `+`: `[ "lsp" "tree-sitter" ]` → `(rust +lsp +tree-sitter)`.

Conditional modules:

```nix
doomemacs.extraModules.os.tty = {
  enable = true;
  when = "(featurep :system 'tty)";
};
```

### 2. Extra packages (`packages.el`)

```nix
doomemacs.extraPackages = [
  { name = "rainbow-delimiters"; }
  {
    name = "my-pkg";
    recipe = {
      host = "github";
      repo = "me/my-pkg";
      files = [ "my-pkg.el" ];
      branch = "main";   # optional
      pin = "abc123";    # optional
    };
  }
];

doomemacs.unpin = [ "org-roam" ];  # already default
```

After rebuild: `doom sync`.

### 3. Extra Elisp

```nix
doomemacs.extraConfigEarly = ''
  ;; top of config.el
'';

doomemacs.extraConfig = ''
  (setq display-time-mode t)
'';

doomemacs.extraInit = ''
  ;; after (doom! ...) in init.el
'';
```

### 4. New feature files (`+foo.el`)

Any `generatedLisp` key that starts with `+` is written into DOOMDIR and
`load!`ed from `config.el`:

```nix
doomemacs.generatedLisp."+mail.el" = ''
  ;;; +mail.el -*- lexical-binding: t; -*-
  (setq user-mail-address "you@example.com")
'';
```

Disable a shipped feature (file omitted from the store):

```nix
doomemacs.features.cursor = false;
```

### 5. Snippets, themes, other files

```nix
doomemacs.extraFiles = {
  "snippets/python-mode/pdb" = ./snippets/python-mode/pdb;
  "themes/my-theme.el" = ./my-theme.el;
  "notes.txt" = "plain text is allowed too";
};
```

### 6. A whole extra Nix module

```nix
# my-doom-python.nix
{ config, lib, pkgs, ... }:
{
  config = lib.mkIf config.doomemacs.enable {
    doomemacs.extraModules.lang.python = {
      enable = true;
      flags = [ "lsp" ];
    };
    doomemacs.generatedLisp."+python.el" = ''
      (after! python (setq python-indent-offset 4))
    '';
    doomemacs.extraBinPackages = [ pkgs.ruff pkgs.pyright ];
  };
}
```

```nix
imports = [
  inputs.doomemacs.homeModules.default
  ./my-doom-python.nix
];
```

Shipped feature modules live in [`modules/features/`](modules/features/) — copy
one as a template.

### 7. UI / LSP / Org knobs

```nix
doomemacs.ui = {
  theme = "doom-one";
  font = { family = "JetBrains Mono"; size = 14; weight = "regular"; };
  variablePitchFont = { family = "Fira Sans"; size = 14; };
  lineNumbers = "relative";  # relative | visual | absolute | none
  extraConfig = "(setq doom-themes-padded-modeline t)";
};

doomemacs.lsp = {
  disableSemgrep = true;
  diagnosticsProvider = "flycheck";  # flycheck | flymake | auto
  uiDoc = { enable = true; delay = 0.5; maxWidth = 100; };
};

doomemacs.org = {
  directory = "~/org/";
  babelLanguages = [ "python" "shell" ];
  roamUi = true;
};

doomemacs.editor.vtermShell = "/run/current-system/sw/bin/nu"; # or null for auto
```

### 8. Emacs package and tools

```nix
doomemacs.emacsPackage = pkgs.emacs30-pgtk;
doomemacs.installEmacs = true;
doomemacs.installDoom = true;   # clone github:doomemacs/doomemacs if missing
doomemacs.extraBinPackages = [ pkgs.texliveFull ];
```

Language servers are pulled in automatically from enabled `lang.*` modules
(rust-analyzer, nixd, typescript-language-server, yaml-language-server, …).

---

## Flake outputs

```text
nixosModules.default      NixOS: emacs, fonts, LSPs
homeModules.default       Home Manager: full DOOMDIR + tools
packages.<system>.doomDir Generated ~/.config/doom tree
overlays.default          pkgs.doomemacsConfig
lib.evalDoom              Evaluate modules → config.doomemacs
lib.mkDoomDir             Render a DOOMDIR derivation
devShells.default         nixfmt, nixd
formatter                 nixfmt-rfc-style
templates.default         examples/
```

Evaluate with extra modules (no Home Manager):

```nix
inputs.doomemacs.lib.mkDoomDir {
  system = "x86_64-linux";
  modules = [ { doomemacs.ui.theme = "doom-one"; } ];
}
```

---

## Layout

```text
flake.nix
lib/elisp.nix              init.el / packages.el / config.el generators
lib/mk-doom-dir.nix        symlinkJoin of generated + static files
modules/options.nix        all doomemacs.* options
modules/defaults.nix       current private config as Nix
modules/features/{ui,editor,lsp,org,cursor}.nix
modules/home-manager.nix
modules/nixos.nix
doom/themes/               noctalia theme
doom/snippets/             yas snippets
examples/extend.nix        copy-paste extension snippet
```

---

## After rebuild

1. `home-manager switch` or `nixos-rebuild switch`
2. If `init.el` or `packages.el` changed: `doom sync`
3. Restart Emacs (`doom/reload` is not enough for new `package!` entries)

`DOOMDIR` is set to `~/.config/doom`. `~/.config/emacs/bin` is prepended to
`PATH` so `doom` works in new shells.

The previous setup symlinked `~/.config/doom` → `~/.dotfiles/doom`. This flake
**replaces** that symlink with a store-backed directory. Keep `~/.dotfiles/doom`
as a reference or delete the symlink after the first successful switch.

---

## Troubleshooting

**Emacs ignores the new config.** Check `echo $DOOMDIR` and that
`~/.config/doom/init.el` starts with “Generated by the doomemacs Nix flake”.

**`doom` command not found.** Open a new terminal (sessionPath) or
`export PATH="$HOME/.config/emacs/bin:$PATH"`. If `installDoom` is on, the
activation clone should have created that tree.

**Packages missing after adding `extraPackages`.** Run `doom sync`, then restart.

**Want to edit Elisp live.** Put experiments in `extraConfig` or a
`generatedLisp."+scratch.el"` file in your Nix config — not in `~/.config/doom`.

**Infinite recursion on `finalDoomDir`.** The Home Manager module strips that
attribute before calling `mkDoomDir`. Custom modules should not assign
`doomemacs.finalDoomDir`.

**NixOS-only, no Home Manager.** The NixOS module does **not** write DOOMDIR.
Use `homeModules.default` (or `nix build .#doomDir` and copy) for the config.

---

## Cursor

Cursor CLI (`agent` / `cursor-agent`) is expected on `PATH` or in
`~/.local/bin` (the Elisp adds that directory). Leader: **`SPC c A`**.

| Key | Command |
|-----|---------|
| `a` | Prompt |
| `i` | Interactive session |
| `r` | Region |
| `o` / `O` | Open file / project in Cursor IDE |
| `L` / `s` / `v` | Login / status / verify |
| `I` | Install/reinstall CLI |

Disable with `doomemacs.features.cursor = false`.

---

## License

Personal configuration flake. Doom Emacs is MIT; vendored theme/snippets follow
their original files.

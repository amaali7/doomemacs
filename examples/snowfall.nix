# Drop-in for a Snowfall Lib host/home (amaali7-style).
#
# flake.nix:
#   inputs.doomemacs.url = "git+file:///home/ai3wm/work/Nix/doomemacs";
#   homes.modules = [ inputs.doomemacs.homeModules.default ];
#   systems.modules.nixos = [ inputs.doomemacs.nixosModules.default ];
#
# homes/x86_64-linux/ai3wm@nvme-0/default.nix (or modules/home/apps/emacs):
{
  doomemacs.enable = true;
}

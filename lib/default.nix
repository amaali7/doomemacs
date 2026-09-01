{ lib }:

{
  elisp = import ./elisp.nix { inherit lib; };

  enabled = {
    enable = true;
  };
  disabled = {
    enable = false;
  };
}

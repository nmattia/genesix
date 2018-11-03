let
  pkgs = import ./nix
    { overlays =
        [ (self: super:
            {
              genesix = import ./genesix { pkgs = self; };
            }
          )
        ];
    };
in
  pkgs.lib.attrsets.mapAttrs
    (name: value:
      pkgs.callPackage (import (./tests + "/${name}")) {} )
    (builtins.readDir ./tests) //
  { site = pkgs.callPackage ./site {}; }

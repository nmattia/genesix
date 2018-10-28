{ genesix, pkgs }:
  genesix.generate
    { rawFiles = [];
      roots = [ ./somefile.nix ];
    }

{ genesix, pkgs }:
  genesix.generate
    { root = pkgs.lib.cleanSource ./files; }

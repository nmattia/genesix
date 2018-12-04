{ genesix, lib }:
  genesix.generate
    { root = lib.cleanSource ./files; }

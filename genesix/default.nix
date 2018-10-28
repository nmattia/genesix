{pkgs}:
let
  genesix-lib = pkgs.callPackage ../genesix-core {};
in genesix-lib //
rec {
  generate = attrs:
    genesix-lib.generateWith (attrs // { generators = defaultGenerators; });
  generateWith = pick: attrs:
    genesix-lib.generateWith (attrs // { generators = pick generators; });
  defaultGenerators = with generators; [ nix ];
  generators =
    { nix =
        (pkgs.callPackage ../genesix-nix { inherit genesix-lib; }).generator;
    };
}

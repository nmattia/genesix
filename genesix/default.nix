{pkgs}:
let
  genesix-lib = pkgs.callPackage ../genesix-core {};
in genesix-lib //
rec {
  generate = attrs:
    genesix-lib.generateWith (attrs // { generators = defaultGenerators; });
  generateWith = pick: attrs:
    genesix-lib.generateWith (attrs // { generators = pick generators; });
  defaultGenerators = with generators; [ html nix ];
  genesix-nix =
        (pkgs.callPackage ../genesix-nix { inherit genesix-lib; }).generator;
  genesix-html =
        (pkgs.callPackage ../genesix-html { inherit genesix-lib genesix-nix; }).generator;
  generators =
    { nix = genesix-nix;
      html = genesix-html;
    };
}

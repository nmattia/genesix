{pkgs}:
let
  genesix-lib = pkgs.callPackage ../genesix-core {};
in genesix-lib //
rec {
  generate = attrs:
  genesix-lib.generateWith attrs
      [ genesix-html genesix-nix genesix-markdown ];
  genesix-markdown =
        (pkgs.callPackage ../genesix-md { inherit genesix-lib; }).generator;
  genesix-nix =
        (pkgs.callPackage ../genesix-nix { inherit genesix-lib; }).generator;
  genesix-html =
        (pkgs.callPackage ../genesix-html { inherit genesix-lib genesix-nix; }).generator;
}

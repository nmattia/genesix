{ pkgs, genesix-lib }:
{
  generator =
    { accept = file:
        pkgs.lib.strings.hasSuffix ".nix" (builtins.toString file);
      gen = args: file:
        let
          imported = import file;
        in
         if builtins.isFunction imported
         then imported (args // { inherit pkgs; })
         else imported;
    };
}

{ pkgs, genesix-lib }:
{
  generator =
    { accept = file:
        pkgs.lib.strings.hasSuffix ".nix" (builtins.toString file);
      gen = {pathOf}: file:
        let
          imported = import file;
          args =
            (genesix-lib.ifArg imported "pkgs" pkgs) //
            (genesix-lib.ifArg imported "pathOf" pathOf) //
            (genesix-lib.ifArg imported "relpath" relpath) //
            (genesix-lib.ifArg imported "abspath" abspath);
          relpath =
            genesix-lib.mkRelPath { inherit pathOf; from = res.outpath;};
          abspath =
            genesix-lib.mkAbsPath { inherit pathOf;};
          res =
            if builtins.isFunction imported then imported args else imported;
        in res;
    };
}

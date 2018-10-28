{ pkgs, genesix-lib }:
{
  generator =
    { accept = file: true; # TODO: based on extension
      gen = {pathOf}: file:
        let
          imported = import file;
          ifArg = arg: val:
            if builtins.hasAttr arg (builtins.functionArgs imported)
            then { ${arg} = val; }
            else {};
          args =
            (ifArg "pkgs" pkgs) //
            (ifArg "pathOf" pathOf) //
            (ifArg "relpath" relpath) //
            (ifArg "abspath" abspath);
          relpath =
            genesix-lib.mkRelPath { inherit pathOf; from = res.outpath;};
          abspath =
            genesix-lib.mkAbsPath { inherit pathOf;};
          res =
            if builtins.isFunction imported then imported args else imported;
        in res;
    };
}

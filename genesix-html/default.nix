{ pkgs, genesix-lib, genesix-nix }:
{
  generator =

    let
      html = null;
    in
    { accept = file:
        pkgs.lib.strings.hasSuffix ".html.nix" (builtins.toString file);
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
            (ifArg "abspath" abspath) //
            (ifArg "html" html);
          relpath =
            genesix-lib.mkRelPath { inherit pathOf; from = res.outpath;};
          abspath =
            genesix-lib.mkAbsPath { inherit pathOf;};
          res =
            if builtins.isFunction imported then imported args else imported;
        in res;
    };
}

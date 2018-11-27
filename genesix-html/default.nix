{ pkgs, genesix-lib, genesix-nix }:
{
  generator =
    { accept = file:
        pkgs.lib.strings.hasSuffix ".html.nix" (builtins.toString file);
      gen = args@{root, relpath, srcpath, ...}: file:
        let
          imported = import file;
          args' = args // { inherit html; };
          html = pkgs.callPackage ./html.nix
              {inherit genesix-lib root file relpath srcpath;};
        in html.render (
              if builtins.isFunction imported
              then imported args'
              else imported);
    };
}

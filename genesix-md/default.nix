{ pkgs, genesix-lib }:
{
  generator =
    { accept = file:
        pkgs.lib.strings.hasSuffix ".md" (builtins.toString file);
      gen = {srcpath', srcpath, relpath, files, root, ... }: file:
        let
          ghc = pkgs.haskellPackages.ghcWithPackages (ps: [ ps.pandoc ]);

          htmlContent = builtins.readFile (pkgs.runCommand "md-to-html"
            { buildInputs = [ pkgs.pandoc ghc ]; }
              ''
                cat ${pkgs.writeText "path-rewrites" (builtins.toJSON rewrites)} > rewrites.json
                pandoc -f markdown -t html --filter ${./RewriteURLs.hs} ${file} > $out
              '');
          rewritePairs =
            builtins.map (f: { name = srcpath f; value = relpath f;} )
            # XXX: this only rewrites paths to the _other_ files:
            ( pkgs.lib.filter (f: f != file) files);
          rewrites = pkgs.lib.listToAttrs rewritePairs;

        in
          { content = htmlContent;
            outpath =
              let
                last = pkgs.lib.last (srcpath' file);
                last' = "${pkgs.lib.removeSuffix ".md" last}.html";
              in pkgs.lib.init (srcpath' file) ++ [ last' ];
          };
    };
}

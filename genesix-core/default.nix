{ pkgs }:
rec {

  mkRelPath = {pathOf, from}: to:
    pkgs.lib.strings.concatStringsSep "/" (
    pkgs.lib.lists.subtractLists from (
    pathOf to));
  mkAbsPath = {pathOf}: to:
    pkgs.lib.strings.concatStringsSep "/" (pathOf to);

  applyGenerator = {generators, pathOf}: file:
    let
      generator =
        pkgs.lib.lists.findFirst
          (gen: gen.accept file)
          (abort "could not find generator for file ${builtins.toString file}")
          generators;
      res = generator.gen {inherit pathOf;} file;
    in res;

  generateWith =
      { rawFiles
      , roots
      , generators
      }:
    let
      createBranch = file:
        let
          filename =
            "genesix/" + pkgs.lib.strings.concatStringsSep "/" file.outpath;
          content =
              if builtins.isString file.content
              then pkgs.writeText "unnamed" file.content
              else file.content;
        in
          pkgs.runCommand "genesix-file" {}
          ''
            dir=$(dirname ${filename})
            mkdir -p $out/$dir
            cp ${content} $out/${filename}
          '';
      generatedsSet =
        let
          toKey = path:
            builtins.unsafeDiscardStringContext (
            builtins.toString path);
          popList = list: def: cont:
            if pkgs.lib.lists.length list <= 0
            then def
            else cont (pkgs.lib.lists.head list) (pkgs.lib.lists.tail list);
          pathOf = target:
            let key = toKey target;
            in
              if builtins.hasAttr key generatedsSet
              then generatedsSet.${key}.outpath
              else abort "no outpath found for file '${key}'";
          apply = applyGenerator { inherit pathOf generators; };
          loop = acc: nexts:
            popList nexts acc (next: rest:
              let
                key = toKey next;
              in
              if acc ? key then loop acc rest
              else
                let
                  res = apply next;
                  deps =
                    if res ? "dependencies"
                    then res.dependencies
                    else [];
                in
                  loop (acc // { ${key} = apply next;}) (rest ++ deps)
                );
        in loop {} roots;
      generateds = builtins.attrValues generatedsSet;
    in
      pkgs.stdenv.mkDerivation
        { name = "genesix";
          src = pkgs.symlinkJoin
            { name = "genesix-symlinks";
              paths = map createBranch (rawFiles ++ generateds);
            };
          installPhase =
            ''
              mkdir -p $out
              ${pkgs.rsync}/bin/rsync -avL genesix/ $out
            '';
        };
}

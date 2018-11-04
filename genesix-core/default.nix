{ pkgs }:
rec {
  ifArg = imported: arg: val:
    if builtins.hasAttr arg (builtins.functionArgs imported)
    then { ${arg} = val; }
    else {};
  listFilesInDir = dir:
    let
      go = dir: dirName:
        pkgs.lib.lists.concatLists
        (
          pkgs.lib.attrsets.mapAttrsToList
            (path: ty:
              if ty == "directory"
              then
                go "${dir}/${path}" "${dirName}${path}/"
              else
                [ "${dirName}${path}" ]
            )
            (builtins.readDir dir)
        );
    in go dir "";

  mkRelPath = {pathOf, from}: to:
    pkgs.lib.strings.concatStringsSep "/" (
    pkgs.lib.lists.subtractLists from (
    pathOf to));
  mkAbsPath = {pathOf}: to:
    pkgs.lib.strings.concatStringsSep "/" (pathOf to);
  mkSrcPath = {root, from}:
    let
      root' = builtins.toString root;
      from' = builtins.toString from;
    in
      if pkgs.lib.hasPrefix root' from'
      then pkgs.lib.splitString "/" (pkgs.lib.removePrefix root' from')
      else abort "file '${from'}' isn't in directory '${root'}'";

  applyGenerator = {generators, pathOf, root}: file:
    let
      generator =
        pkgs.lib.lists.findFirst
          (gen: gen.accept file)
          (abort "could not find generator for file ${builtins.toString file}")
          generators;
      res =
        let
          args =
            {} //
            (ifArg generator.gen "pathOf" pathOf) //
            (ifArg generator.gen "root" root);
        in generator.gen args file;
    in res;

  generateWith =
      { root
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
          apply = applyGenerator { inherit pathOf generators root; };

        in pkgs.lib.lists.foldl (acc: next:
            let
              key = toKey next;

            # XXX: it's important that the accumulator is on the right. Since
            # // is right-biased, we use laziness to compute values only once.
            in { ${key} = apply next; } // acc
          ) {} (map (f: "${builtins.toString root}/${builtins.toString f}") (listFilesInDir root));

      generateds = builtins.attrValues generatedsSet;
    in
      pkgs.stdenv.mkDerivation
        { name = "genesix";
          src = pkgs.symlinkJoin
            { name = "genesix-symlinks";
              paths = map createBranch generateds;
            };
          installPhase =
            ''
              mkdir -p $out
              ${pkgs.rsync}/bin/rsync -avL genesix/ $out
            '';
        };
}

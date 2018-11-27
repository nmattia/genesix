{ pkgs }:
rec {
  toKey = path:
    builtins.unsafeDiscardStringContext (
    builtins.toString path);
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

  # source: the original file, before the generator has been applied
  # target: the resulting file, after the generator has been applied
  # rel: from current target to other target
  # abs: from the root to current target
  # src: from the root to current source
  # foo vs. foo': foo is a path, foo' is a list of components
  # in all cases, the arguments (from, to) are the original (Nix) paths.
  mkRelPath = {generated, from}: to:
    let
      from_target' = generated.${toKey from}.outpath;
      to_target' = generated.${toKey to}.outpath;
    in
      pkgs.lib.strings.concatStringsSep "/" (
      pkgs.lib.lists.subtractLists
        from_target'
        to_target'
      );
  mkAbsPath = {generated}: to:
    let
      to_target' = generated.${toKey to}.outpath;
    in
      pkgs.lib.strings.concatStringsSep "/" to_target';

  mkSrcPath = {root, file}:
    let
      file_source = toKey file;
      root' = builtins.toString root;
    in
      if pkgs.lib.hasPrefix root' file_source
      then pkgs.lib.splitString "/" (pkgs.lib.removePrefix root' file_source)
      else abort "file '${file_source}' isn't in directory '${root'}'";

  applyGenerator = {generators, generated, root}: file:
    let
      generator =
        pkgs.lib.lists.findFirst
          (gen: gen.accept file)
          (abort "could not find generator for file ${builtins.toString file}")
          generators;
      args =
        { inherit generated root;
          abspath = to: mkAbsPath { inherit generated; } to;
          relpath = to: mkRelPath { inherit generated; from = file; } to;
          srcpath = mkSrcPath { inherit root file; };
        };
    in generator.gen args file;

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
      generated =
        let
          apply = applyGenerator
              { inherit generated generators root; };

        in pkgs.lib.lists.foldl (acc: next:
            let
              key = toKey next;

            # XXX: it's important that the accumulator is on the right. Since
            # // is right-biased, we use laziness to compute values only once.
            in { ${key} = apply next; } // acc
          ) {} (map (f: "${builtins.toString root}/${builtins.toString f}") (listFilesInDir root));

    in
      pkgs.stdenv.mkDerivation
        { name = "genesix";
          src = pkgs.symlinkJoin
            { name = "genesix-symlinks";
              paths = map createBranch (builtins.attrValues generated);
            };
          installPhase =
            ''
              mkdir -p $out
              ${pkgs.rsync}/bin/rsync -avL genesix/ $out
            '';
        };
}

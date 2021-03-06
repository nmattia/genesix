{ pkgs }:
rec {
  toKey = path:
    builtins.unsafeDiscardStringContext (
    builtins.toString path);
  # NOTE:
  # this returns a list of paths, not store paths, e.g.:
  #   /home/foo/...
  #   /home/bar/baz.quux
  #
  listFilesInDir = dir:
    let
      go = dir:
        pkgs.lib.lists.concatLists
        (
          pkgs.lib.attrsets.mapAttrsToList
            (path: ty:
              if ty == "directory"
              then
                go (dir + "/${path}")
              else
                [ (dir + "/${path}") ]
            )
            (builtins.readDir dir)
        );
    in go dir;

  # source: the original file, before the generator has been applied
  # target: the resulting file, after the generator has been applied
  # rel: from a target to another target
  # tgt: from the root to a target
  # src: from the root to a source
  # foo vs. foo': foo is a path, foo' is a list of components
  # in all cases, the arguments (from, to) are the original (Nix) paths.
  mkRelPath = {generated}: from: to:
    let
      from_target' = generated.${toKey from}.outpath;
      to_target' = generated.${toKey to}.outpath;
    in
      pkgs.lib.lists.subtractLists
        from_target'
        to_target';
  mkTgtPath = {generated}: to:
    let
      to_target' = generated.${toKey to}.outpath;
    in to_target';
  mkSrcPath = {root}: to:
    let
      to_source = toKey to;
      root' = builtins.toString root + "/";
    in
      if pkgs.lib.hasPrefix root' to_source
      then pkgs.lib.splitString "/" (pkgs.lib.removePrefix root' to_source)
      else abort "file '${to_source}' isn't in directory '${root'}'";

  applyGenerator = {generators, generated, root, files}: file:
    let
      generator =
        pkgs.lib.lists.findFirst
          (gen: gen.accept file)
          (abort "could not find generator for file ${builtins.toString file}")
          generators;
      args =
        rec { inherit generated root files file;
          relpath = to: pkgs.lib.concatStringsSep "/" (relpath' file to);
          relpath' = from: to: mkRelPath { inherit generated;} from to;
          srcpath = to: pkgs.lib.concatStringsSep "/" (srcpath' to);
          srcpath' = to: mkSrcPath { inherit root; } to;
          tgtpath = to: pkgs.lib.concatStringsSep "/" (tgtpath' to);
          tgtpath' = to: mkTgtPath { inherit generated; } to;
        };
    in generator.gen args file;

  generateWith =
      { root
      }: generators:
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
          files = listFilesInDir root;
          apply = applyGenerator
              { inherit generated generators root files; };

        in pkgs.lib.lists.foldl (acc: next:
            let
              key = toKey next;

            # XXX: it's important that the accumulator is on the right. Since
            # // is right-biased, we use laziness to compute values only once.
            in { ${key} = apply next; } // acc
          ) {} files ;

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

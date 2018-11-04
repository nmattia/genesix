# The HTML library
{pkgs, genesix-lib, root, file, pathOf, relpath}:
rec {
  saturatePretag = tag:
    let
      res =
        if builtins.isFunction tag then
          if builtins.isFunction (tag null)
          then tag null null
          else tag null
        else tag;
    in
      if builtins.isAttrs res then res else
      abort "Saturation failed, leftover type is ${builtins.typeOf res}";

  mkPretag = tagName:
    arg1: arg2: { inherit arg1 arg2 tagName; };

  # TODO: if tag content or attr value has context, abort
  pretag2Tag = pretag:
    let
        pretag' = saturatePretag pretag;
        attrs = if builtins.isNull pretag'.arg1 then {} else pretag'.arg1;
        tagname = pretag'.tagname;
        renderedAttrs =
          pkgs.lib.concatStrings (
            pkgs.lib.attrsets.mapAttrsToList
            # TODO: do the relpath thing IFF v is a path
            (k: v: " ${k}=\"${relpath v}\"")
            attrs
            );
    in if builtins.isNull pretag'.arg2 then
        "<" + pretag'.tagName + renderedAttrs + "/>" else
        "<" + pretag'.tagName + renderedAttrs + ">" +
          pretag'.arg2 + "</" + pretag'.tagName + ">";

  # All HTML tags
  tags =
    pkgs.lib.foldl
      (xs: x: xs // { "${x}" = mkPretag x; })
      {}
      (pkgs.lib.strings.splitString "\n" (pkgs.lib.readFile ./html-tags));

  # All these should return a list of pretags
  renderPretag = pretag: [(pretag2Tag pretag)];

  renderListOfPretags = map pretag2Tag;

  srcpath =
    genesix-lib.mkSrcPath { inherit root; from = file;};

  render = input:
    let
      listOfPretags =
        if builtins.isList input then renderListOfPretags input else
        if builtins.isAttrs input then renderPretag input else
        abort "Cannot deal with builtins.typeOf input";
    in render' listOfPretags;

  render' = tags:
    { content = pkgs.lib.concatStrings tags;
      outpath =
        let
          last = pkgs.lib.last srcpath;
          last' = pkgs.lib.removeSuffix ".nix" last;
        in  pkgs.lib.init srcpath ++ [ last' ];
    };
}

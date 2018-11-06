# The HTML library
{pkgs, genesix-lib, root, file, pathOf, relpath}:
rec {

  # All HTML tags
  tags =
    pkgs.lib.foldl
      (xs: x: xs // { "${x}" = mkHTMLTag x; })
      {}
      (pkgs.lib.strings.splitString "\n" (pkgs.lib.readFile ./html-tags));

  # Rendering { foo = "bar"; } to foo="bar"
  renderHTMLAttributes = attrs:
          pkgs.lib.concatStrings (
            pkgs.lib.attrsets.mapAttrsToList
            # TODO: do the relpath thing IFF v is a path
            (k: v:
              let
                v' =
                  if builtins.typeOf v == "path"
                  then relpath v
                  else builtins.toString v;
              in " ${k}=\"${v'}\"")
            attrs
            );

  # Feed with nulls until it's not a function anymore
  saturate = pkgs.lib.fix (f: v:
    if builtins.isFunction v then f (v null) else v);

  mkHTMLTag = tagName:
    arg1: arg2:
      let pretag =
        { inherit arg1 arg2 tagName; };
      in
    let
        attrs = if builtins.isNull pretag.arg1 then {} else pretag.arg1;
        tagname = pretag.tagname;
        renderedAttrs = renderHTMLAttributes attrs;
    in if builtins.isNull pretag.arg2 then
        "<" + pretag.tagName + renderedAttrs + "/>" else
        "<" + pretag.tagName + renderedAttrs + ">" +
          pretag.arg2 + "</" + pretag.tagName + ">";

  xmlTag = attrs:
    let
      renderedAttrs = renderHTMLAttributes attrs;
    in
      "<?xml${renderedAttrs}?>";

  srcpath =
    genesix-lib.mkSrcPath { inherit root; from = file;};

  render = input:
    let
      str =
        if builtins.isList input
        then pkgs.lib.concatMapStrings saturate input
        else saturate input;
    in
      { content = str;
        outpath =
          let
            last = pkgs.lib.last srcpath;
            last' = pkgs.lib.removeSuffix ".nix" last;
          in  pkgs.lib.init srcpath ++ [ last' ];
      };
}

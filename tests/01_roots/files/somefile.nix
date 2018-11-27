{ pkgs, ...}:

{ content = pkgs.writeText "foo" "foo content";
  outpath = [ "foo" ];
}

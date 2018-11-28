{ tgtpath, ... }:

{ content = "The other file is here: ${tgtpath ./someotherfile.nix}";
  outpath = [ "foo" "bar" ];
}

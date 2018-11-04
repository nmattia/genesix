{ abspath }:

{ content = "The other file is here: ${abspath ./someotherfile.nix}";
  outpath = [ "foo" "bar" ];
}

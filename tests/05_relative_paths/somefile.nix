{ relpath }:

{ content = "The other file is here: ${relpath ./someotherfile.nix}";
  outpath = [ "foo" "bar" ];
  dependencies = [ ./someotherfile.nix ];
}

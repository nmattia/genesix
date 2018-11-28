{ pkgs
, relpath
, relpath'
, srcpath
, srcpath'
, tgtpath
, tgtpath'
, files
, ... }:

{ content =
    ''
      tgtpath ./someotherfile.nix: ${tgtpath ./someotherfile.nix}
      tgtpath' ./someotherfile.nix: ${builtins.toString (tgtpath' ./someotherfile.nix)}

      relpath ./someotherfile.nix: ${relpath ./someotherfile.nix}
      relpath' ./somefile.nix ./someotherfile.nix: ${builtins.toString (relpath' ./somefile.nix ./someotherfile.nix)}

      srcpath' ./somefile.nix: ${builtins.toString (srcpath' ./somefile.nix)}
      srcpath: ${srcpath}

      files: ${builtins.toString files}
    '';
  outpath = [ "foo" "bar" ];
}

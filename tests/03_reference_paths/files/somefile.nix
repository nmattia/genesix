{ pkgs
, relpath
, relpath'
, srcpath
, srcpath'
, tgtpath
, tgtpath'
, files
, file
, ... }:

{ content =
    ''
      tgtpath ./someotherfile.nix: ${tgtpath ./someotherfile.nix}
      tgtpath' ./someotherfile.nix: ${builtins.toString (tgtpath' ./someotherfile.nix)}

      relpath ./someotherfile.nix: ${relpath ./someotherfile.nix}
      relpath' ./somefile.nix ./someotherfile.nix: ${builtins.toString (relpath' ./somefile.nix ./someotherfile.nix)}

      srcpath' ./somefile.nix: ${builtins.toString (srcpath' ./somefile.nix)}
      srcpath ./somefile.nix: ${srcpath file}

      builtins.map srcpath files: ${builtins.toString (builtins.map srcpath files)}
    '';
  outpath = [ "foo" "bar" ];
}

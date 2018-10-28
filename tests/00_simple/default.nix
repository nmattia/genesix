{ genesix, pkgs }:
  genesix.generate
    { rawFiles =
        [ { outpath = ["foo"];
            content = pkgs.writeText "baz" "foo content";
          }
        ];
      roots = [];
    }

# The default set of packages
with { fetch = import ./fetch.nix; };
import (fetch "nixpkgs")

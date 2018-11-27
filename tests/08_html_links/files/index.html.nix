{ html, ... }:
[ (html.xmlTag { version = "1.0"; encoding = "UTF-8"; })
  (html.tags.a { href = ./page.html.nix; } "Go to some other page?")
  (html.commentTag " this is a comment!! ")
]

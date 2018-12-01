#!/usr/bin/env runhaskell
{-# LANGUAGE LambdaCase #-}

import Data.List (stripPrefix)
import System.FilePath (joinPath, splitDirectories)
import qualified Data.Aeson as JSON
import qualified Data.Map as Map
import qualified Text.Pandoc.JSON as Pandoc

-- | JSON filter that replaces URLs.
--
-- It reads the mappings from the file "rewrites.json".
main :: IO ()
main = do
    rewrites <- JSON.decodeFileStrict "./rewrites.json" >>= \case
      Just mp -> pure mp
      Nothing -> error "Could not decode rewrites file"
    Pandoc.toJSONFilter (rewriteURLs rewrites)

-- | Rewrite the urls using the provided mappings.
rewriteURLs :: Map.Map String String -> Pandoc.Inline -> Pandoc.Inline
rewriteURLs mp = \case
  Pandoc.Link a b (url, c) -> Pandoc.Link a b (replaceURL mp url, c)
  x -> x

-- | Turns "./foo/bar" into "foo/bar"
canonicalURL :: String -> String
canonicalURL = joinPath . dropWhile ("." ==) . splitDirectories

replaceURL :: Map.Map String String -> String -> String
replaceURL mp url = case Map.lookup (canonicalURL url) mp of
    Just x -> x
    Nothing -> url

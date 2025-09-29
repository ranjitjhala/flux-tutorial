#!/usr/bin/env runhaskell

import System.Environment (getArgs)
import Data.Char (toUpper, isSpace)
import Data.List (isPrefixOf)
import Text.Printf (printf)


convertStackedFigures :: String -> String
convertStackedFigures = unlines . concatMap convertLine .  lines
  where
    convertLine :: String -> [String]
    convertLine s
      | "| <img src" `isPrefixOf` s = ["||", s]
      | otherwise                   = [s]

convertChapterLinks :: String -> String
convertChapterLinks = concatMap convertWord . tokenize



convertCodeBlocks :: String -> String
convertCodeBlocks = unlines . map convertLine . lines
  where
    convertLine :: String -> String
    convertLine s
      | "``` fluxhidden" `isPrefixOf` s = "```rust, editable, hidden"
      | "``` flux"       `isPrefixOf` s = "```rust, editable"
      | otherwise = s

convertWord :: String -> String
convertWord w
  | ['\\', '[', 'c', 'h', '\\', ']', ':'] `isPrefixOf` w =
    let suffix = drop 7 w
        (link, rest) = span (/= '.') suffix
        (file, sec)  = splitColon link
        section      = if null sec then "" else '#' : sec
    in
      printf "[this chapter](ch%s.md%s)%s" file section rest
  | otherwise = w

splitColon :: String -> (String, String)
splitColon s =
  let (before, after) = break (== ':') s
  in case after of
       ':':rest -> (before, rest)
       _        -> (before, "")

-- ch:foo:bar --> [this chapter](chfoo.md#bar)

tokenize :: String -> [String]
tokenize [] = []
tokenize s@(c:_)
    | isSpace c = let (ws, rest) = span isSpace s
                  in ws : tokenize rest
    | otherwise = let (nonWs, rest) = break isSpace s
                  in nonWs : tokenize rest

convert :: String -> String
convert = convertStackedFigures . convertCodeBlocks . convertChapterLinks

main :: IO ()
main = do
  args <- getArgs
  case args of
    [filename] -> do
      content <- readFile filename
      writeFile (filename ++ ".out") (convert content)
      putStrLn $ "Successfully converted " ++ filename
    _ -> putStrLn "Usage: ./uppercase.hs <filename>"

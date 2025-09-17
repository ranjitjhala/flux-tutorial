#!/usr/bin/env runhaskell

import System.Environment (getArgs)
import Data.Char (toUpper, isSpace)
import Data.List (isPrefixOf)


convertChapterLinks :: String -> String
convertChapterLinks = concatMap convertWord . tokenize



convertCodeBlocks :: String -> String
convertCodeBlocks = unlines . map convertLine . lines
  where
    convertLine :: String -> String
    convertLine s
      | "``` flux" `isPrefixOf` s = "```rust, editable"
      | otherwise = s

convertWord :: String -> String
convertWord w
  | ['\\', '[', 'c', 'h', '\\', ']', ':'] `isPrefixOf` w =
    let suffix = drop 7 w
        (file, rest) = span (/= '.') suffix
    in
      "[this chapter](ch" ++ file ++ ".md)" ++ rest
  | otherwise = w

tokenize :: String -> [String]
tokenize [] = []
tokenize s@(c:_)
    | isSpace c = let (ws, rest) = span isSpace s
                  in ws : tokenize rest
    | otherwise = let (nonWs, rest) = break isSpace s
                  in nonWs : tokenize rest

convert :: String -> String
convert = convertCodeBlocks . convertChapterLinks

main :: IO ()
main = do
  args <- getArgs
  case args of
    [filename] -> do
      content <- readFile filename
      writeFile (filename ++ ".out") (convert content)
      putStrLn $ "Successfully converted " ++ filename
    _ -> putStrLn "Usage: ./uppercase.hs <filename>"

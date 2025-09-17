#!/usr/bin/env runhaskell

import System.Environment (getArgs)
import System.IO (hPutStrLn, stderr)
import System.Exit (exitFailure)
import System.Directory (doesFileExist)
import Data.List (isPrefixOf)

main :: IO ()
main = do
    args <- getArgs
    case args of
        [filename] -> do
            exists <- doesFileExist filename
            if exists
                then processFile filename
                else do
                    hPutStrLn stderr $ "Error: File '" ++ filename ++ "' does not exist"
                    exitFailure
        _ -> do
            hPutStrLn stderr "Usage: ./convert_to_rs.hs <input_file>"
            exitFailure

processFile :: FilePath -> IO ()
processFile filename = do
    content <- readFile filename
    let linesOfFile = lines content
    let processedLines = processLines False linesOfFile
    putStrLn "/*"
    mapM_ putStrLn processedLines
    putStrLn "*/"

processLines :: Bool -> [String] -> [String]
processLines _ [] = []
processLines inFluxBlock (line:rest)
    -- Check if line starts a flux code block
    | isFluxStart line =
        "*/" : "" : "" : "" : processLines True rest
    -- Check if line ends any code block (only when in flux block)
    | inFluxBlock && line == "```" =
        "" : "" : "" : "/*" : processLines False rest
    -- If we're inside a flux block, echo the actual line
    | inFluxBlock =
        line : processLines True rest
    -- Otherwise, just echo the line (it will be commented out)
    | otherwise =
        line : processLines False rest

isFluxStart :: String -> Bool
isFluxStart line = "```flux" `isPrefixOf` line
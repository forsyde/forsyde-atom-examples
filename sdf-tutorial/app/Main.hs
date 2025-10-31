module Main (main) where

import Lib
import ForSyDe.Atom.MoC.SDF as SDF

main :: IO ()
main = print $ system (SDF.signal [1..10])

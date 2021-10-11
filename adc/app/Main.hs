module Main where

import ForSyDe.Atom.Utility.Plot
import SARNoise

import System.Random


main = do
  gen <- getStdGen
  (v1, v2, v3) <- test3
  plotGnu $ prepareL (noJunkCfg {xmax = 5, rate=0.3}) [v1,v2,v3]

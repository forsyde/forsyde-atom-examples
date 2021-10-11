module SARNoise where

import SAR
import Utils
import WeightedRandom as W
import ForSyDe.Atom
import ForSyDe.Atom.Prob.Normal as N
import System.Random

import ForSyDe.Atom.MoC.CT as CT 
import ForSyDe.Atom.MoC.DE as DE 
import ForSyDe.Atom.MoC.SY as SY 
import ForSyDe.Atom.MoC.SY.Clocked as MRSY
import ForSyDe.Atom.Skel.Vector as V
import ForSyDe.Atom.MoC.Time as T

noisy :: Integer -> CT.Signal Voltage -> CT.Signal (Dist Voltage)
noisy p = CT.comb11 (normal (2^^p))


noisy' :: Integer -> DE.Signal Voltage -> DE.Signal (Dist Voltage)
noisy' p = DE.comb11 (N.normal (2^^p))

comp' :: Int -> SY.Signal (Dist Voltage) -> SY.Signal (Dist Voltage)
     -> SY.Signal (Dist Binary)
comp' x = SY.comb21 (trans41 choose one zero)
  where
    one  = W.weighted [(x,0),(100-x,1)]
    zero = W.weighted [(x,1),(100-x,0)]
    choose o z v_i v_c
      | v_i >= v_c = o
      | otherwise  = z

sar' :: SY.Signal Bool -> SY.Signal (Dist Binary)
    -> SY.Signal (V.Vector Binary)
    -> SY.Signal (Dist (V.Vector Binary))
sar' = SY.moore31 nsSar' (trans11 fst) (W.noDist (V.fanoutn bigN 0, V.fanoutn bigN 0))
  where nsSar' approx ready comp_in reg_in =
          trans21 (\a c -> nsSar a ready c reg_in) approx comp_in

dac' :: Voltage -> SY.Signal (Dist (V.Vector Binary)) -> SY.Signal (Dist Voltage)
dac' v_ref = SY.comb11 (trans11 (convertDac v_ref))

sarAdc' x v_ref s_in = (sar_out, ready)
  where
    (sh_reg, ready) = shiftReg
    sar_bit = sar' ready comp_out sh_reg
    sar_out = dac' v_ref sar_bit
    comp_out = comp' x s_in sar_out


-- test ------------------------

nz = -4

-- de2ct :: DE.Signal a -> CT.Signal a
-- de2ct = DE.toCT1 . DE.comb11 Prelude.const

viCT'' = noisy nz $ CT.infinite1 (realToFrac . (+1) . T.sin)
viCT' = CT.infinite1 (realToFrac . (+1) . T.sin)
clkDE' = DE.generate1 id (0.1,()) :: DE.Signal ()
shrDE' = DE.generate1 id (0.8,()) :: DE.Signal ()
-- clkDE'' = DE.generate1 id (0.05,()) :: DE.Signal ()
viDE' = noisy' nz $ sampDE1 shrDE' viCT' :: DE.Signal (Dist Voltage)
-- viCT'' = DE.toCT1 $ DE.comb11 Prelude.const $ noisy' nz
--          $ sampDE1 clkDE'' viCT' :: CT.Signal (Dist Voltage)
(clkSY',viSY') = DE.toSY1 $ DE.comb21 (\c a -> a) clkDE' viDE'

gengens c gs = de2ct $ SY.toDE (SY.generate1 (+c) 0) (SY.signal gs) 

test2' :: CT.Signal Voltage -> CT.Signal (Dist Voltage)
test2' v = vo
  where (sar_out, ready) = sarAdc' 2 1.0 viSY'
        vo = sy2ct' clkSY $ MRSY.delay (W.noDist 0)
             $ (sy2sy' sar_out) `MRSY.when` (sy2sy' ready)
        -- vi = DE.toCT1 $ DE.comb11 Prelude.const viDE

test3 = do
  gen <- getStdGen
  let vihs :: CT.Signal Voltage
      gens = mkStdGens gen
      vihs = CT.comb21 N.sample (gengens 0.8 gens) $ de2ct viDE'
      vis = CT.comb21 N.sample (gengens 0.01 gens) viCT''
      vos = CT.comb21 N.sample (gengens 0.8 gens) $ test2' viCT'
  return (vis, vihs, vos)


cfg4 = noJunkCfg {xmax = 15, rate=0.01}
cfg5 = noJunkCfg {xmax = 0.5, rate=0.01}

compTest = de2ct $ SY.toDE clkSY'
  $ comp' 1 viSY' $ SY.constant1 (W.noDist 1)

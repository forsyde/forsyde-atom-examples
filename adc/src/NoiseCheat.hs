module NoiseCheat where

import SAR (Voltage,Binary,dac,sar,shiftReg,bool2bit)
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

comp' :: Int -> SY.Signal StdGen
      -> SY.Signal Voltage -> SY.Signal Voltage -> SY.Signal Binary
comp' x gens s1 = SY.comb21 N.sample gens . SY.comb11 spice
                  . SY.comb21 (\v_i v_c -> bool2bit $ v_i >= v_c) s1
  where
    spice 1 = one
    spice _ = zero
    one  = W.weighted [(x,0),(100-x,1)]
    zero = W.weighted [(x,1),(100-x,0)]
 
noisy :: Integer -> SY.Signal StdGen -> SY.Signal Voltage -> SY.Signal Voltage
noisy p gens =  SY.comb21 N.sample gens . SY.comb11 (normal (2^^p))

noisy' :: Integer -> TimeStamp -> SY.Signal StdGen
       -> DE.Signal Voltage -> DE.Signal Voltage
noisy' p ts gens =  DE.comb21 N.sample degens . DE.comb11 (normal (2^^p))
  where
    degens = SY.toDE (SY.generate1 (+ts) 0) gens :: DE.Signal StdGen

sarAdc wt gens s_in = (sar_out, ready)
  where
    (sh_reg, ready) = shiftReg
    sar_bit = sar ready comp_out sh_reg
    sar_out = dac vref sar_bit
    comp_out = comp' wt gens s_in sar_out

-- -- test ------------------------

cfg = noJunkCfg {xmax = 25, rate=0.01}
cfg1 = noJunkCfg {xmax = 25, rate=0.01,
                 labels = ["app-adc-t3-vi", "app-adc-t3-vish", "app-adc-t3-vo"]}

plotTs = SY.generate1 (+0.01) 0
sarTs  = SY.generate1 (+0.1) 0
shTs   = SY.generate1 (+0.8) 0

plotClk = SY.toDE plotTs $ SY.constant1 ()
sarClk  = SY.toDE  sarTs $ SY.constant1 ()
shClk   = SY.toDE   shTs $ SY.constant1 ()

viClean  = CT.infinite1 (realToFrac . (+1) . T.sin)
viPlot  g= sy2ct plotTs $ noisy nz g $ ct2sy plotClk viClean
viSH     = sampDE1 shClk viClean
viNoise g= noisy' nz shPeriod g viSH
viSY    g= snd $ DE.toSY1 $ DE.comb21 (\_ a -> a) sarClk $ viNoise g 

test3 = do
  gen <- getStdGen
  let gens = SY.signal $ mkStdGens gen
      vi   = viPlot gens
      vish = de2ct $ viNoise gens
      (sar_out, ready) = sarAdc wt gens (viSY gens)
      vo = sy2ct' sarTs $ MRSY.delay 0
           $ (sy2sy' sar_out) `MRSY.when` (sy2sy' ready)
  return (vi,vish,vo)

nz = -3
vref = 2.0
wt = 30
shPeriod = 0.8



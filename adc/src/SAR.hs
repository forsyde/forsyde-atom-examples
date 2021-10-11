module SAR where

import Utils
import ForSyDe.Atom
import ForSyDe.Atom.Skel.Vector as V
import ForSyDe.Atom.MoC.SY as SY
import ForSyDe.Atom.MoC.SY.Clocked as MRSY
import ForSyDe.Atom.MoC.DE as DE 
import ForSyDe.Atom.MoC.DE.React as RE
import ForSyDe.Atom.MoC.CT as CT 
import ForSyDe.Atom.MoC
import ForSyDe.Atom.ExB.Absent
import ForSyDe.Atom.Utility.Plot

import ForSyDe.Atom.MoC.TimeStamp as Ts


  
-- helper -----------------------

bin2float True = 1.0
bin2float _    = 0.0

bor 0 0 = 0
bor _ _ = 1

band 1 1 = 1
band _ _ = 0

bit2real = realToFrac
bool2bit False = 0
bool2bit _ = 1
 
-- regular code -----------------

bigN = 8

moore02 ns od i = SY.comb12 od $ SY.generate1 ns i 
  
type Voltage    = Double
type Binary     = Int

shiftReg :: (SY.Signal (V.Vector Binary), SY.Signal Bool)
shiftReg = moore02 V.rotr od (1 :> V.fanoutn (bigN - 1) 0)
  where
    od reg = (reg, V.last reg == 1)

sar :: SY.Signal Bool -> SY.Signal Binary -> SY.Signal (V.Vector Binary)
    -> SY.Signal (V.Vector Binary)
sar = SY.moore31 nsSar fst (V.fanoutn bigN 0, V.fanoutn bigN 0)

nsSar (p_approx, pp_approx) ready comp_in reg_in
  | ready        = (V.fanoutn bigN 0, V.fanoutn bigN 0)
  | comp_in == 1 = (V.farm21 bor p_approx reg_in ,p_approx)
  | otherwise    = (V.farm21 bor pp_approx reg_in ,pp_approx)


dac :: Voltage -> SY.Signal (V.Vector Binary) -> SY.Signal Voltage
dac v_ref = SY.comb11 (convertDac v_ref)

convertDac v_ref reg = V.reduce (+) $ V.farm21 voltageLevel V.indexes reg
  where
    voltageLevel i b = (bit2real b) * (v_ref / 2 ^ i )

comp :: SY.Signal Voltage -> SY.Signal Voltage -> SY.Signal Binary
comp = SY.comb21 (\v_i v_c -> bool2bit $ v_i >= v_c)

sarAdc v_ref s_in = (sar_out, ready)
  where
    (sh_reg, ready) = shiftReg
    sar_bit = sar ready comp_out sh_reg
    sar_out = dac v_ref sar_bit
    comp_out = comp s_in sar_out

-- test ------------------------

clkDE = DE.generate1 id (0.1,()) :: DE.Signal ()
shrDE = DE.generate1 id (0.8,()) :: DE.Signal ()

-- viCT = CT.generate1 (\x -> x - 0.3) (1,const 1) :: CT.Signal Voltage
viCT :: CT.Signal Voltage
viCT =CT.infinite1 f
  where
    f t | t < 1 = 1
        | t < 2 = 0.7
        | t < 3 = 0.4
        | t < 4 = 0.1
        | otherwise = 0.0

viDE = sampDE1 shrDE viCT
(clkSY,viSY) = DE.toSY1 $ DE.comb21 (\_ a -> a) clkDE viDE

test1 v = (sy2ct clkSY, sy2ct clkSY . bool2bin)
          $$ sarAdc 1.0 viSY

test2 v = (vi, vo)
  where (sar_out, ready) = sarAdc 1.0 viSY
        vo = sy2ct' clkSY $ MRSY.delay 0
             $ (sy2sy' sar_out) `MRSY.when` (sy2sy' ready)
        vi = DE.toCT1 $ DE.comb11 const viDE

-- plot ------------------------

cfg0 = noJunkCfg {xmax = 4, rate=0.01}
cfg1 = noJunkCfg {xmax = 4.1, rate=0.01, labels = ["app-adc-t1-vi", "app-adc-t1-ready", "app-adc-t1-vo"]}
cfg2 = noJunkCfg {xmax = 4.1, rate=0.01, labels = ["app-adc-t2-vi", "app-adc-t2-vish", "app-adc-t2-vo"]}

          
-- tsc = SY.generate1 (+0.1) 0 :: SY.Signal TimeStamp
-- tsh = SY.generate1 (+0.8) 0 :: SY.Signal TimeStamp
-- vi1 = CT.generate1 (\x -> x - 0.3) (1,const 1) :: CT.Signal Voltage
-- shrDE = SY.toDE tsh (SY.constant1 ())



-- viSY = snd $ DE.toSY1 $ CT.sampDE1 clkDE vi1
-- (tsCLK,clkSY) = DE.toSY1 (DE.generate1 id (0.1,()) :: DE.Signal ()) 
-- sy2ct = DE.toCT1 . SY.toDE tsCLK . SY.comb11 const  :: SY.Signal a -> CT.Signal a



-- testBench v = (sy2ct, sy2ct . SY.comb11 bin2float)
--               $$ sarAdc 1.0 clkSY (snd $ DE.toSY1 $ CT.sampDE1 shrDE v)



-- -- multi-rate ------------------------

-- sy2mrsy = SY.comb11 Prst

-- adc_out si = MRSY.delay 0 $ (sy2mrsy sar_out) `MRSY.when` (sy2mrsy ready)
--   where (sar_out, ready) = sarAdc 1.0 $ snd $ DE.toSY1 $ CT.sampDE1 clkDE si

-- mrsy2ct = DE.toCT1 . RE.toDE1 . RE.fromSYC1 ts1 . MRSY.comb11 const  :: MRSY.Signal a -> CT.Signal a

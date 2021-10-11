module FFT where

import Utils
import Data.Complex
import ForSyDe.Atom.MoC
import ForSyDe.Atom.MoC.CT as CT
-- import ForSyDe.Atom.MoC.Time as T
import ForSyDe.Atom.Skel.FastVector as V
import qualified ForSyDe.Atom.Skel.Vector as VV
import ForSyDe.Atom.Skel.FastVector.DSP as V
import ForSyDe.Atom.Utility.Plot
import ForSyDe.Atom

type Cpx = Complex Float
bN = 7 :: Int
bins = 2^bN
fs = 900    
ts = 1/fs 
tp = 1/(3*900)
-- tp = ts

-----------------------------------------

cfg1 = noJunkCfg {xmax = 0.5, rate = realToFrac ts,
                 labels = ["app-fft-si"]}
cfg2 = noJunkCfg {xmax = 0.5, rate = realToFrac ts,
                 labels = ["app-fft-vsi", "app-fft-vso"]}
cfg3 = noJunkCfg {xmax = 0.5, rate = realToFrac ts,
                 labels = ["app-fir-si", "app-fir-so"]}



si :: CT.Signal Float
si = CT.infinite1 $ \t ->
  1 * sin(2 * pi * 50 * fromRational t + 0) +
  3 * sin(2 * pi * 120 * fromRational t + 2)

sampler :: CT.Signal Cpx -> Vector (CT.Signal Cpx)
sampler = V.recuri delayLine
  where
    delayLine = V.fanoutn (bins - 1) (CT.delay ts (\_ -> 0 :+ 0))


bfly :: Cpx -> CT.Signal Cpx -> CT.Signal Cpx -> (CT.Signal Cpx, CT.Signal Cpx)
bfly w = CT.comb22 (\x0 x1 -> (x0 + w * x1, x0 - w * x1))

dut = fft'' bfly bN

-----------------------------------------------------

vsi = sampler $ CT.comb11 (:+ 0) si
vsiPlot = CT.comb11 v2vv $ zipx' $ V.farm11 (CT.comb11 realPart) vsi
vsoPlot = CT.comb11 v2vv $ zipx' $ V.farm11 (CT.comb11 magnitude) $ V.take (bins `div` 2)  $ dut vsi

-----------------------------------------------------
-- TEST FIR

coefs = vector $ 
        [-0.033911398711183
        , -0.016280832436647293
        , -0.05443356757435481
        , -0.01719697755289656
        , -0.054099424771237456
        , 0.020819877466979303
        , -0.008552921541722215
        , 0.09956290332312434
        , 0.06703134681939811
        , 0.18277075527635275
        , 0.1257901357429818
        , 0.21863805009307685
        , 0.1257901357429818
        , 0.18277075527635275
        , 0.06703134681939811
        , 0.09956290332312434
        , -0.008552921541722215
        , 0.020819877466979303
        , -0.054099424771237456
        , -0.01719697755289656
        , -0.05443356757435481
        , -0.016280832436647293
        , -0.033911398711183] :: Vector Float
firNet :: CT.Signal Float -> CT.Signal Float                           
firNet = V.fir' (CT.comb21 (+)) (\c -> CT.comb11 (*c)) (CT.delay ts (\_ -> 0)) coefs 

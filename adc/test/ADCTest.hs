module ADCTest where

import ForSyDe.Atom.MoC
import Test.QuickCheck as QC
import Test.QuickCheck.Function
import Test.Framework
import Test.Framework.Providers.QuickCheck2 (testProperty)
import System.Random
import ForSyDe.Atom.Prob.Normal as N

import SAR (Voltage)
import NoiseCheat
import Utils
import ForSyDe.Atom.MoC.DE as DE
import ForSyDe.Atom.MoC.SY as SY
import ForSyDe.Atom.MoC.SY.Clocked as MRSY
import ForSyDe.Atom.Utility.Plot

nmin = 1000
nmax = 100000
err  = 0.125 * vref :: Voltage
pwr  = 2^^(-3) :: Voltage
nerrs = 40
comperr = 4

stdGens :: Gen [StdGen]
stdGens = sized $ \n ->
  do k <- choose (nmin,nmax)
     n <- arbitrary
     let gen = mkStdGen n
         gens = mkStdGens gen
     return $ take k gens

prop_adc cperr = forAll stdGens $ \g ->
   errs g (de2Lst $ voplot $ SY.signal g)
   where
     -- nsCout s x y = if abs (x-y) > err then s+1 else s
     -- odStop g s = s > (length g `div` nerrs)
     -- clks = (SY.generate1 (+shPeriod) 0)
     vclean   = SY.constant1 1.13
     vi g     = noisy' (-4) shPeriod g $ DE.constant1 1.13
     viplot g = DE.delay shPeriod 0 $ vi g
     voplot g = sarAdc'' cperr g (vi g)
     -- so g = let gens = SY.signal g
     --        in sarAdc'' gens $ SY.toDE shTs $
     --           SY.comb21 (\sd -> N.sample sd . normal pwr) gens side
     -- errs = (==False) . last . SY.fromSignal .  snd . DE.toSY1
     -- toLst = DE.fromSignal
     errs g l = (< (length g `div` nerrs))
                $ foldr (\x s -> if abs (1.13 - x) > err then s+1 else s) 0 l


sarAdc'' cerr gens si = so
  where
    vsy    = snd $ DE.toSY1 $ DE.comb21 (\c a -> a) sarClk si
    (sar_out, ready) = sarAdc cerr gens vsy
    so = sy2de' sarTs $ MRSY.delay 0
         $ (sy2sy' sar_out) `MRSY.when` (sy2sy' ready)

tests :: [Test]
tests = [
  testGroup " ADC tests "
    [ testProperty "Test Max error rate: 16" (withMaxSuccess 100 $ prop_adc 16)
    , testProperty "Test Max error rate: 15" (withMaxSuccess 100 $ prop_adc 15)
    , testProperty "Test Max error rate: 14" (withMaxSuccess 100 $ prop_adc 14)
    , testProperty "Test Max error rate: 13" (withMaxSuccess 100 $ prop_adc 13)
    , testProperty "Test Max error rate: 12" (withMaxSuccess 100 $ prop_adc 12)
    , testProperty "Test Max error rate: 11" (withMaxSuccess 100 $ prop_adc 11)
    , testProperty "Test Max error rate: 10" (withMaxSuccess 100 $ prop_adc 10)
    ]
  ]

main :: IO()
main = defaultMain tests

vclean = DE.constant1 1.13
vi g = noisy' (-4) shPeriod g vclean
viplot g = DE.delay shPeriod 0 $ vi g
cfgx = noJunkCfg {xmax = 100, rate = 0.8}
voplot g = sarAdc'' 10 g (vi g)

countNumErr g = foldr (\x s -> if abs (1.13 - x) > err then s+1 else s) 0
                $ take 10000 $ de2Lst (voplot g)

module Utils where

import ForSyDe.Atom.MoC.CT as CT
-- import ForSyDe.Atom.MoC.Time as T
import ForSyDe.Atom.Skel.FastVector as V
import qualified ForSyDe.Atom.Skel.Vector as VV
import ForSyDe.Atom.Skel.FastVector.DSP as V
import ForSyDe.Atom


v2vv = VV.vector . V.fromVector
mapS = fmap . fmap
unit' = V.vector . (:[])
last' = last . V.fromVector
init' = V.vector . init . V.fromVector
reduce1 :: (a1 -> a -> a ->  a) -> Vector a1 -> Vector a -> a
reduce1 p v1 vs = V.pipe (V.farm21 p v1 (init' vs)) (last' vs)

zipx' :: Vector (CT.Signal a) -> CT.Signal (Vector a)
zipx' =  reduce sync . farm11 (mapS unit')
  where sync = CT.comb21 (<++>)

fft'' butterfly k vs | n == 2^k = bitrev $ (stage `V.pipe1` (V.iterate k (*2) 2)) vs
  where
    stage   w = V.concat . V.farm21 segment (twiddles n) . V.group w
    segment t = (><) unduals . (><) (V.farm22 (butterfly t)) . duals
    n         = V.length vs        -- length of input

module AtomExamples.GettingStarted.SY where

import ForSyDe.Atom.MoC
import ForSyDe.Atom.ExB.Absent
import ForSyDe.Atom.ExB as ExB 
import ForSyDe.Atom.MoC.SY as SY
import ForSyDe.Atom.Skeleton.Vector as V

s1SY = SY.signal [1,2,3,4,5]
s2SY = SY.generate1 (+1) 0
proc1SY = SY.comb21 (+)


-- s2SYAbs :: SY.Signal (AbstExt Integer)
s2SYAbs = SY.comb11 Prst s2SY

s1SYAbs :: SY.Signal (AbstExt Integer)
s1SYAbs = let mask = SY.signal [True, True, False, True, False]
          in  SY.comb21 ExB.filter' mask s1SY

proc2SYAbs :: (Num a, ExB b)
           => SY.Signal (b a)
           -> SY.Signal (b a)
           -> SY.Signal (b a)
proc2SYAbs = SY.comb21 (ExB.res21 (+))

pcSY :: Num a => a -> SY.Signal a -> SY.Signal a
pcSY = SY.moore11 (+) id


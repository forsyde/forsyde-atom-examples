module Utils where

import ForSyDe.Atom.MoC
import ForSyDe.Atom.MoC.CT as CT 
import ForSyDe.Atom.MoC.DE as DE 
import ForSyDe.Atom.MoC.DE.React as RE 
import ForSyDe.Atom.MoC.SY as SY 
import ForSyDe.Atom.MoC.SY.Clocked as MRSY
import ForSyDe.Atom.ExB.Absent



-- utilities ------------------------

ct2sy clk = snd . DE.toSY1 . CT.sampDE1 clk
sy2sy' = SY.comb11 Prst

sy2ct :: SY.Signal TimeStamp -> SY.Signal a -> CT.Signal a
sy2ct clk = DE.toCT1 . SY.toDE clk . SY.comb11 const

sy2ct' :: SY.Signal TimeStamp -> MRSY.Signal a -> CT.Signal a
sy2ct' clk = DE.toCT1 . RE.toDE1 . RE.fromSYC1 clk . MRSY.comb11 const

sy2de' :: SY.Signal TimeStamp -> MRSY.Signal a -> DE.Signal a
sy2de' clk = RE.toDE1 . RE.fromSYC1 clk


de2ct :: DE.Signal a -> CT.Signal a
de2ct = DE.toCT1 . DE.comb11 Prelude.const

de2Lst :: DE.Signal a -> [a]
de2Lst = fromStream . fmap (\(DE _ v) -> v)

bool2bin = SY.comb11 bin2float

bin2float True = 1.0
bin2float _    = 0.0

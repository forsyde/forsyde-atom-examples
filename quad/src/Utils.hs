module Utils where

import ForSyDe.Atom.MoC
import ForSyDe.Atom.MoC.Time as T
import ForSyDe.Atom.MoC.TimeStamp as Ts
import ForSyDe.Atom.MoC.CT as CT 
import ForSyDe.Atom.MoC.DE as DE 
import ForSyDe.Atom.MoC.DE.React as RE 
import ForSyDe.Atom.MoC.SY as SY 
import ForSyDe.Atom.MoC.SY.Clocked as MRSY
import ForSyDe.Atom.ExB.Absent
import ForSyDe.Atom.Utility.Plot

int :: (TimeStamp -> TimeStamp -> a -> (Time -> a) -> (Time -> a))
    -> TimeStamp
    -> a
    -> CT.Signal a -> CT.Signal a 
int solver step x0 x'
  = let (ts, sy) = DE.toSY1 $ CT.toDE1 x'
        out      = SY.state21 ns (\_->x0) ts sy
        ns p t f = solver step t (p $ time t) f
    in DE.toCT1 $ SY.toDE ts out


euler :: TimeStamp    -- the step for the solver precision 
      -> TimeStamp    -- t0
      -> Rational            -- the "history" of the integral at t0
      -> (Time -> Rational)  -- integrand function
      -> Time -> Rational    -- the output integrated function
euler step t0 x0 f t = iter x0 t0
  where
    iter st ti
      | t <= realToFrac ti = st
      | otherwise = iter (trapez st (time $ ti - step) (time ti)) (ti + step)
    h = time step
    trapez prev t_0 t_1 = prev + (h * (f t_0 + f t_1) / 2)

x = CT.signal [(0,\_->1),(1,\_->1),(2,\_->1)]  :: CT.Signal Rational
x' = CT.signal [(0,\t->(-t)),(1,\t->(-t)),(2,\t->(-t))]  :: CT.Signal Rational
y = int euler 0.01 3

cfg1 = noJunkCfg {xmax = 3, rate = 0.01, labels = ["moc-ct-int-si", "moc-ct-int-so"]}


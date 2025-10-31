module Lib
    ( system
    ) where

import ForSyDe.Atom.MoC.SDF as SDF

-- System Netlist
system s_in = s_out where
  s_1 = p_1 s_in s_6_delayed
  (s_2, s_3) = p_2 s_1
  s_6 = p_3 s_3 s_5
  (s_out, s_4) = p_4 s_2
  s_5 = p_5 s_4
  s_6_delayed = SDF.delay [0,0] s_6

-- Process Specification
p_1 = SDF.actor21 ((2,1), 1, f_1)
  where f_1 [x1,x2] [y] = [x1+x2+y]
p_2 = SDF.actor12 (1, (1,1), f_2)
  where f_2 [x] = ([x],[x+1])
p_3 = SDF.actor21 ((2,2), 2, f_3)
  where f_3 [x1,x2] [y1,y2] = [x1+x2,y1+y2]
p_4 = SDF.actor12 (1, (3,1), f_4)
  where f_4 [x] = ([x,x+1,x+2],[x])
p_5 = SDF.actor11 (1, 1, f_5)
  where f_5 [x] = [x+1]

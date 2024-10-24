module Lib
    (
      someFunc
    ) where

import ForSyDe.Atom.MoC.DE as DE 
import ForSyDe.Atom.MoC (takeS)

someFunc :: IO ()
someFunc = putStr "Hallo"

-- 
-- * Definition of signals
--
s1 :: DE.Signal Integer
s1 = DE.signal [(0,0), (2,4)]
s2 :: DE.Signal Integer
s2 = DE.signal [(0,1), (5,2)]
-- >>> s1
-- {0@0s,4@2s}
-- >>> s2
-- {1@0s,2@5s}

--
-- * Definition of combinational processes
--
p1 :: (Num a) => DE.Signal a -> DE.Signal a
p1 = DE.comb11 (+1)
-- >>> p1 s1
-- {1@0s,5@2s}

p2 :: (Num a) => DE.Signal a -> DE.Signal a -> (DE.Signal a, DE.Signal a)
p2 = DE.comb22 f where
  f a b = (a + b, a - b)
-- >>> p2 s1 s2
-- ({1@0s,5@2s,6@5s},{-1@0s,3@2s,2@5s})

x :: DE.Signal Integer
--x :: DE.SignalBase TimeStamp Integer
x = DE.delay 1.9 1 s1
-- >>> x
-- {1@0s,0@1.9s,4@3.9s}

--
-- * Definition of sequential processes
--
d1 :: TimeStamp -> Integer -> DE.Signal Integer -> DE.Signal Integer
d1 = DE.delay
-- >>> d1 0.3 1 s1
-- {1@0s,0@0.3s,4@2.3s}

fsm1 :: (TimeStamp, Integer) -> DE.Signal Integer -> DE.Signal Integer  
fsm1 = DE.moore11 (+) (*2)
-- >>> takeS 5 $ fsm1 (0.5, 100) s1 
-- {200@0s,200@0.5s,200@1s,200@1.5s,200@2s}

fsm2 ::  (TimeStamp, Integer) -> DE.Signal Integer -> DE.Signal Integer
fsm2 = DE.mealy11 (+) (*)
-- >>> takeS 5 $ fsm2 (0.5, 1000) s1
-- {0@0s,4000@2s,4000@100s,4016@102s,4016@200s}

--
-- * Feedback loop
--
system :: DE.Signal Integer -> DE.Signal Integer
system sin = sout where
  state = delay 0.5 100 nextstate
  nextstate = comb21 (+) sin state
  sout = comb11 (*2) state
-- >>> takeS 5 $ system s1
-- {200@0s,200@0.5s,200@1s,200@1.5s,200@2s}
  
--
-- * Adaptive processes
--
-- Adaptive signals
sf1 :: DE.Signal (Integer -> Integer)
sf1 = DE.signal [(0,(+1)), (50,(+2))]

sf2 :: DE.Signal (Integer -> Integer -> Integer)
sf2 = DE.signal [(0,(+)), (50,(*))]

a1 :: DE.Signal Integer
a1 = DE.reconfig11 sf1 s1
-- >>> a1
-- {1@0s,5@2s,6@50s}

a2 :: DE.Signal Integer
a2 = DE.reconfig21 sf2 s1 s2 
-- >>> a2 
-- {1@0s,5@2s,6@5s,8@50s}

--
-- * Example 5.1.1. Encoder/Decoder
--
s_key :: DE.Signal Integer
s_key = DE.signal [(0,1), (1,2), (2,3)]

s_enc_in :: DE.Signal Integer
s_enc_in = DE.signal [(0,10), (1,2), (2,32)]


encDec :: DE.Signal Integer -> DE.Signal Integer -> DE.Signal Integer
encDec s_k s_e = s_d where
  s_enc = DE.comb11 (+) s_k
  s_dec = DE.comb11 (flip (-)) s_k
  s_channel = DE.reconfig11 s_enc s_e
  s_d = DE.reconfig11 s_dec s_channel
-- >>> encDec s_key s_enc_in
-- {10@0s,2@1s,32@2s}

--
-- * Example 5.1.1. Encoder/Decoder with delays
--
encDec' :: DE.Signal Integer -> DE.Signal Integer -> DE.Signal Integer 
encDec' s_k s_e = s_d where
  s_enc = DE.comb11 (+) s_k
  s_dec = DE.delay 20 (+0) $ DE.comb11 (flip (-)) s_k
  --s_dec_delayed = delay 20 0 s_dec
  s_channel = DE.delay 20 0 $ DE.reconfig11 s_enc s_e
  s_d = DE.reconfig11 s_dec s_channel
-- >>> encDec' s_key s_enc_in
-- {0@0s,10@20s,2@21s,32@22s}

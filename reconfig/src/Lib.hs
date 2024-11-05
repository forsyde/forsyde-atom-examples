{-# OPTIONS_GHC -Wno-unused-binds #-}
{-# OPTIONS_GHC -Wno-unused-imports #-}
{- HLINT ignore "Use camelCase" -}

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
s_1 :: DE.Signal Integer
s_1 = DE.signal [(0,0), (2,4)]
s_2 :: DE.Signal Integer
s_2 = DE.signal [(0,1), (5,2)]
-- >>> s_1
-- {0@0s,4@2s}
-- >>> s_2
-- {1@0s,2@5s}

--
-- * Definition of combinational processes
--
p_1 :: (Num a) => DE.Signal a -> DE.Signal a
p_1 = DE.comb11 (+1)
-- >>> p_1 s_1
-- {1@0s,5@2s}

p_2 :: (Num a) => DE.Signal a -> DE.Signal a -> (DE.Signal a, DE.Signal a)
p_2 = DE.comb22 f where
  f a b = (a + b, a - b)
-- >>> p_2 s_1 s_2
-- ({1@0s,5@2s,6@5s},{-1@0s,3@2s,2@5s})

x :: DE.Signal Integer
x = DE.delay 1.9 1 s_1
-- >>> x
-- {1@0s,0@1.9s,4@3.9s}

--
-- * Definition of sequential processes
--
d_1 :: TimeStamp -> Integer -> DE.Signal Integer -> DE.Signal Integer
d_1 = DE.delay
-- >>> d_1 0.3 1 s_1
-- {1@0s,0@0.3s,4@2.3s}

fsm1 :: (TimeStamp, Integer) -> DE.Signal Integer -> DE.Signal Integer  
fsm1 = DE.moore11 (+) (*2)
-- >>> takeS 5 $ fsm1 (0.5, 100) s_1 
-- {200@0s,200@0.5s,200@1s,200@1.5s,200@2s}

fsm2 ::  (TimeStamp, Integer) -> DE.Signal Integer -> DE.Signal Integer
fsm2 = DE.mealy11 (+) (*)
-- >>> takeS 5 $ fsm2 (0.5, 1000) s_1
-- {0@0s,0@0.5s,0@1s,0@1.5s,4000@2s}

--
-- * Feedback loop
--
system :: DE.Signal Integer -> DE.Signal Integer
system s_in = s_out where
  s_state = delay 0.5 100 s_nextstate
  s_nextstate = comb21 (+) s_in s_state
  s_out = comb11 (*2) s_state
-- >>> takeS 5 $ system s_1
-- {200@0s,200@0.5s,200@1s,200@1.5s}
  
--
-- * Adaptive processes
--
-- Adaptive signals
s_f1 :: DE.Signal (Integer -> Integer)
s_f1 = DE.signal [(0,(+1)), (50,(+2))]

s_f2 :: DE.Signal (Integer -> Integer -> Integer)
s_f2 = DE.signal [(0,(+)), (50,(*))]

a_1 :: DE.Signal Integer
a_1 = DE.reconfig11 s_f1 s_1
-- >>> a_1
-- {1@0s,5@2s,6@50s}

a_2 :: DE.Signal Integer
a_2 = DE.reconfig21 s_f2 s_1 s_2 
-- >>> a_2 
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

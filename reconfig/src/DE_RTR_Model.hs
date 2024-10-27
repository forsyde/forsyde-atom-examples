-- Based on the drawing in Google Drive:
-- https://docs.google.com/drawings/d/16zvZg_HNuOdysuJJ78xylbqKone9SYuSopHV8vs7tik/edit

module DE_RTR_Model where

import ForSyDe.Atom.MoC.DE
import ForSyDe.Atom.MoC (takeS)


-- |The 'rtrSystem' models a run-time reconfigurable system, where the active function is selected via a trigger signal. The trigger signal specifies the index of the function that shall be performed.
de_rtrSystem :: Num a => [a -> a]
                   -> Signal (Maybe Integer) -- ^The trigger signal specifies the index of the function to be activated
                   -> Signal a           -- ^The input signal
                   -> Signal a           -- ^The output signal
de_rtrSystem configurations s_trigger s_in = s_out
   where
     s_out = worker s_conf s_in
     s_initiate = handler s_trigger
     (s_fetch, s_conf) = steward s_initiate s_data
     s_data = delay 1 (+1) (configRepo configurations s_fetch)
-- >>>  takeS 10 $ de_rtrSystem [(+1), (+2), (*10), (+100)] (signal [(0,Nothing), (1,Just 1), (2,Just 1), (3,Just 2), (4,Just 2)]) (signal [(0,1),(1,2)])
-- {2@0s,3@1s,4@2s,4@3s,20@4s,20@5s,20@6s,20@7s,20@8s,20@9s}

{- |
The 'handler' initiates the reconfigurations by telling the Steward to fetch a given
configuration from the configuration repository.
-}
handler :: Signal (Maybe Integer) -- ^The trigger signal specifies the index of the function to be activated
        -> Signal (Maybe Integer) -- ^The initiation signal specifies the index of the function to be loaded
handler = comb11 h
  where h Nothing  = Nothing
        h (Just x) = Just x

-- | The 'worker' executes the functionality provided by the 'steward'
--   with parameters from the 'handler'.  
worker :: Signal (a -> a) -- ^ Signal that specifies the function to be loaded and executed 
         -> Signal a        -- ^ Input signal
         -> Signal a        -- ^ Output signal
worker = reconfig11
-- >>> let s1 = signal [(0,0),(1,1),(2,2)]
-- >>> let sf = signal [(0,(+1)),(1,(+10)),(2,(+100))]
-- >>> worker sf s1
-- {1@0s,11@1s,102@2s}

-- | The 'steward' starts the reconfiguration process and “informs” the 'worker'
--   that it is under reconfiguration and then fully configured. This could also be
--   achievd by mode configuration. The reconfiguration is is started based on an initiation signal.
--   The 'stewart' fetches the configuration from the configuration repo and loads it into the worker.
steward :: Num a => Signal (Maybe Integer)   -- ^The initiation signal specifies the index of the function to be loaded
                 -> Signal (a -> a)      -- ^The signal receiving the functions from the configuration repository
                 -> (Signal Integer,         -- ^The signal that specifies the index
                                         --  of the function to be loaded from the configuration repo
                    Signal (a -> a))     -- ^The signal with the functions that
                                         --  shall be loaded into the worker  
steward = mealy22 ns o (1, (0, (+1)))
   where -- Next state function
         ns :: (Integer, a -> a) -> Maybe Integer -> (a -> a) -> (Integer, a -> a)
         ns state Nothing    _   = state
         ns _     (Just x)  conf = (x, conf)
         -- Output function
         o :: (Integer, a -> a) -> Maybe Integer -> (a -> a) -> (Integer, a -> a)
         o  _     Nothing   conf = (0, conf)
         o  _     (Just x)  conf = (x, conf)

-- | The 'configRepo' (configuration repository) contains the different functions
--   which are fetched by the 'steward' and loaded into the 'worker'.
--   It takes a signal of indexes and returns the function corresponding to the index
configRepo :: [a -> b]
           -> Signal Integer  -- ^The signal that specifies the index
                                 --  of the function to be loaded from the configuration repo 
           -> Signal (a -> b) -- ^The signal with the function that
                                 --  shall be loaded into the worker
configRepo configurations = comb11 (fetch configurations) where
   fetch cs index = cs !! fromIntegral index
-- >>> configurations = [(+1), (+2), (*10)]
-- >>> reconfig11 (configRepo configurations (signal [(0,0),(1,1),(2,2)])) (signal [(0,0),(1,1),(2,2)])
-- {1@0s,3@1s,20@2s}



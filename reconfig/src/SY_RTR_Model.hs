-- Based on the drawing in Google Drive:
-- https://docs.google.com/drawings/d/16zvZg_HNuOdysuJJ78xylbqKone9SYuSopHV8vs7tik/edit

module SY_RTR_Model where

import ForSyDe.Atom.MoC.SY 
import ForSyDe.Atom.MoC (takeS)
import ForSyDe.Atom.ExB.Absent

{- |
The 'handler' initiates the reconfigurations by telling the Steward to fetch a given
configuration from the configuration repository.
-}
handler = undefined

-- | The 'worker' executes the functionality provided by the 'steward'
--   with parameters from the 'handler'.  
worker :: Signal (a -> a) -- ^ Signal that specifies the function to be loaded and executed 
         -> Signal a        -- ^ Input signal
         -> Signal a        -- ^ Output signal
worker = reconfig11
-- >>> let s1 = signal [0,1,2]
-- >>> let sf = signal [(+1),(+10),(+100)]
-- >>> worker sf s1
-- {1,11,102}

-- | The 'steward' starts the reconfiguration process and “informs” the 'worker'
--   that it is under reconfiguration and then fully configured. This could also be
--   achievd by mode configuration. 
steward = undefined


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
-- >>> reconfig11 (configRepo configurations $ signal [0..2]) (signal [1,10,100])
-- {2,12,10000}



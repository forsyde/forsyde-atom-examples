-- Based on the drawing in Google Drive:
-- https://docs.google.com/drawings/d/16zvZg_HNuOdysuJJ78xylbqKone9SYuSopHV8vs7tik/edit

module RTR_Model where

import ForSyDe.Atom.MoC.SY as SY
import ForSyDe.Atom.MoC.DE as DE 
import ForSyDe.Atom.MoC (takeS)
import ForSyDe.Atom.ExB.Absent

{- |
The 'handler' initiates the reconfigurations by telling the Steward to fetch a given
configuration from the configuration repository.
-}
handler = undefined

-- | The 'workerSY' executes the functionality provided by the 'steward'
--   with parameters from the 'handlerSY'.  
workerSY :: SY.Signal (a -> a) -- ^ Signal that specifies the function to be loaded and executed 
         -> SY.Signal a        -- ^ Input signal
         -> SY.Signal a        -- ^ Output signal
workerSY = SY.reconfig11
-- >>> let s1 = SY.signal [0,1,2]
-- >>> let sf = SY.signal [(+1),(+10),(+100)]
-- >>> workerSY sf s1
-- {1,11,102}

-- | The 'steward' starts the reconfiguration process and “informs” the 'worker'
--   that it is under reconfiguration and then fully configured. This could also be
--   achievd by mode configuration. 
steward = undefined


-- | The 'configRepo' (configuration repository) contains the different functions
--   which are fetched by the 'steward' and loaded into the 'worker'.
--   It takes a signal of indexes and returns the function corresponding to the index
configRepo :: [a -> b]
           -> SY.Signal Integer  -- ^The signal that specifies the index
                                 --  of the function to be loaded from the configuration repo 
           -> SY.Signal (a -> b) -- ^The signal with the function that
                                 --  shall be loaded into the worker
configRepo configurations = SY.comb11 (fetch configurations) where
   fetch cs index = cs !! fromIntegral index
-- >>> configurations = [(+1), (+2), (*3)]
-- >>> SY.reconfig11 (configRepo configurations $ SY.signal [0..2]) (SY.signal [1,10,100])
-- {2,12,300}



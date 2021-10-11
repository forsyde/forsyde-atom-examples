module Main where

import ForSyDe.Atom
import ForSyDe.Atom.MoC.TimeStamp
import ForSyDe.Atom.MoC.SDF as SDF
import ForSyDe.Atom.MoC.SAXX

data Airport = ARL | CDG | SKG deriving (Show, Eq)

data Flight = Flight { num  :: Int
                     , dest :: Airport } deriving (Show)

type MFlight = Msg Flight

-- Delay specifications
flightTime = sec 5 :: TimeStamp
landTime   = sec 1 :: TimeStamp

-- An airport 
airport :: DE.Signal Flight -- ^ scheduled flights
        -> DE.Signal Flight -- ^ flights from neighbor 1
        -> DE.Signal Flight -- ^ flights from neighbor 2
        -> (DE.Signal Flight, DE.Signal Flight, DE.Signal Flight)
        -- ^ (to neighbor 1, to neighbor 2, landed)
airport = undefined



-- SADF controller taking care of the landing procedure, and sarisfying the constraint: there is only one landing pad and a plane takes 'landTime' amount to land, during which other planes have to wait.
-- holdPlane :: SDF.Signal TimeStamp -> SDF.Signal MFlight -> SDF.Signal MFlight -> (SDF.Signal TimeStamp, SDF.Signal Flight)
-- holdPlane ts fl1 fl2 = SADF.kernel22 control fl1 fl2
--   where
--     control = SADF.detector31 (1,1,1) ns od (0,[]) ts fl1 fl2
--     ns (t,_) [ts] [M f1] [M f2] = queue t ts [f1, f2]
--     ns (t,_) [ts] [M f1] [NM]   = queue t ts [f1]
--     ns (t,_) [ts] [NM]   [M f2] = queue t ts [f2]
--     ns (t,_) [ts] [NM]   [NM]   = (t, [])
--     queue t ts qs
--       | t < ts = (ts + dly qs, qs)
--       | otherwise = (t + dly qs, qs)
--     dly = (*landTime) . sec . toInteger . length
--     ------------------------------------
--     od (_,[]) = (1        , [((1,1), (0,0), \_ _ -> ([],[]))])
--     od (t,qs) = (length qs, reverse $ zipWith (mkScen t) [0,1] qs)
--     mkScen t d q = ((0,0), (1,1), \_ _-> ([t-d*landTime], [q]))

-- holdPlane :: SDF.Signal TimeStamp -> SDF.Signal (Msg Flight)
--           -> SDF.Signal TimeStamp -> SDF.Signal (Msg Flight)
--           -> (SDF.Signal Timestamp, SDF.Signal (Msg Flight))
-- holdPlane = SADF.kernel22 control
--   where
--     control = SADF.detector41 (1,1,1,1) ns od (0,[])
--     ns (t,_) ts1 fl1 ts2 fl2
--       | ts1 == ts2 = (ts1, feed [fl1, fl2])


main :: IO ()
main = do
  putStrLn "Nothing"

-------------------------------------------------------------

de2sdf :: DE.Signal a -> (SDF.Signal TimeStamp, SDF.Signal (Msg a))
de2sdf a = (|<) $ fmap extract a
  where extract (DDE t a) = (SDF t, SDF a)


sync :: DE.Signal a -> DE.Signal b -> DE.Signal a
sync a b = (\x _ -> x) -.- a -*- b
  
-------------------------------------------------------------

f = Flight 120 ARL
g = Flight 230 CDG
ts = SDF.signal [1, 2, 5, 7]:: SDF.Signal TimeStamp
fl1 = SDF.signal [Just f, Nothing, Just f, Just f]
fl2 = SDF.signal [Just g, Just g, Nothing, Just g]

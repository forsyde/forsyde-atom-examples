module Main where

import ForSyDe.Atom
import ForSyDe.Atom.MoC.TimeStamp
import ForSyDe.Atom.MoC.DE as DE
import ForSyDe.Atom.MoC.SDF as SDF
import ForSyDe.Atom.MoC.SDF.SADF as SADF

data Airport = ARL | CDG | SKG deriving (Show, Eq)

data Flight = Flight { num  :: Int
                     , dest :: Airport } deriving (Show)

type MFlight = Maybe Flight

-- Delay specifications
flightTime = sec 5 :: TimeStamp
landTime   = sec 1 :: TimeStamp

-- An airport 
airport :: DE.Signal Flight -- ^ scheduled flights
        -> DE.Signal MFlight -- ^ flights from neighbor 1
        -> DE.Signal MFlight -- ^ flights from neighbor 2
        -> (DE.Signal MFlight, DE.Signal MFlight, DE.Signal Flight)
        -- ^ (to neighbor 1, to neighbor 2, landed)
airport = undefined


-- SADF controller taking care of the landing procedure, and sarisfying the constraint: there is only one landing pad and a plane takes 'landTime' amount to land, during which other planes have to wait.
holdPlane :: SDF.Signal TimeStamp -> SDF.Signal MFlight -> SDF.Signal MFlight -> (SDF.Signal TimeStamp, SDF.Signal Flight)
holdPlane ts fl1 fl2 = SADF.kernel22 control fl1 fl2
  where
    control = SADF.detector31 (1,1,1) ns od (0,[]) ts fl1 fl2
    ns (t,_) [ts] [Just f1] [Just f2] = queue t ts [f1, f2]
    ns (t,_) [ts] [Just f1] [Nothing] = queue t ts [f1]
    ns (t,_) [ts] [Nothing] [Just f2] = queue t ts [f2]
    ns (t,_) [ts] [Nothing] [Nothing] = (t, [])
    queue t ts qs
      | t < ts = (ts + dly qs, qs)
      | otherwise = (t + dly qs, qs)
    dly = (*landTime) . sec . toInteger . length
    ------------------------------------
    od (_,[]) = (1        , [((1,1), (0,0), \_ _ -> ([],[]))])
    od (t,qs) = (length qs, reverse $ zipWith (mkScen t) [0,1] qs)
    mkScen t d q = ((0,0), (1,1), \_ _-> ([t-d*landTime], [q]))



main :: IO ()
main = do
  putStrLn "Nothing"


f = Flight 120 ARL
g = Flight 230 CDG
ts = SDF.signal [1, 2, 5, 7]:: SDF.Signal TimeStamp
fl1 = SDF.signal [Just f, Nothing, Just f, Just f]
fl2 = SDF.signal [Just g, Just g, Nothing, Just g]

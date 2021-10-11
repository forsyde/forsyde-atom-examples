module WeightedRandom where

import ForSyDe.Atom.Prob.Uniform
import System.Random

weighted :: [(Int,a)] -> Dist a
weighted l
  | weights /= 100 = error "The summed weights need to be 100%"
  | otherwise = Dist $ map (\n -> lup n lut) . randomRs (0,99)
  where
    weights   = sum $ map fst l
    (wts,vals)= unzip l
    mkWeights = reverse $ snd $
                foldl (\(cur,ws) w -> (cur + w, (cur,cur+w-1): ws)) (0,[]) wts
    lut       = zip mkWeights vals
    lup n []  = error "reached end of LUT!"
    lup n (((l,r),v):ls)
      | n >= l && n <= r = v
      | otherwise = lup n ls

noDist a = Dist $ \_ -> repeat a

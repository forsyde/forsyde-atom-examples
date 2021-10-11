module QuadSY where

import Data.List
import ForSyDe.Shallow

instance Functor Signal where
  fmap _ NullS = NullS
  fmap f (s:-ss) = f s :- fmap f ss

-- vectorDot :: (Num a) => Vector a -> Vector a -> a
-- vectorDot v1 v2 = reduceV (+) $ zipWithV (*) v1 v2

-- | The function is of the form
-- x'(t) = f<p>(w(t), t, x(t), u(t))
-- where p is the vector of parameters, w is a vector function of "disturbances",
-- u is a vector function if inputs (the force provided by the engines, not the voltage to the
-- engines themselves) and x is the vector of states.
--
quadcopterParametrizedDynamics :: (Floating a) =>
  Vector a -> -- Vector of parameters
  Vector a -> -- Vector of disturbances
  Vector a -> -- Vector of states
  Vector a -> -- Vector of inputs
  Vector a    -- Vector of derivatives 
quadcopterParametrizedDynamics
  (iner_x:>iner_y:>iner_z:>m:>g:>NullV)
  (tau_wx:>tau_wy:>tau_wz:>f_wx:>f_wy:>f_wz:>NullV)
  (phi:>theta:>psi:>p:>q:>r:>u:>v:>w:>x:>y:>z:>NullV)
  (tau_x:>tau_y:>tau_z:>f_t:>NullV) =
    vector [
      p + r * cos(phi) * tan(theta) + q * sin(phi) * tan(theta),
      q * cos(phi) - r * sin(phi),
      r * cos(phi)/cos(theta) + q * sin(phi)/cos(theta),
      (iner_y - iner_z)/iner_x * r * q + (tau_x + tau_wx)/iner_x,
      (iner_z - iner_x)/iner_y * r * q + (tau_y + tau_wy)/iner_y,
      (iner_x - iner_y)/iner_z * r * q + (tau_z + tau_wz)/iner_z,
      r * v - q * w - g * sin(theta) + f_wx/m,
      p * w - r * u - g * sin(phi) * cos(theta) + f_wy/m,
      q * u - p * v - g * cos(phi) * cos(theta) + (f_wz - f_t)/m,
      w*sin(phi)*sin(psi) + w*cos(phi)*cos(psi)*cos(theta) -
        v*(cos(phi)*sin(psi) - cos(psi)*sin(phi)*sin(theta)) + u*cos(psi)*cos(theta),
      v*(cos(phi)*cos(psi) + sin(psi)*sin(phi)*sin(theta)) -
        w*(cos(psi)*sin(phi) - cos(phi)*sin(psi)*sin(theta)) + u*cos(theta)*sin(psi),
      w*cos(phi)*cos(theta) - u*sin(theta) + v*cos(theta)*sin(phi)
    ]
quadcopterParametrizedDynamics _ _ _ _ = error "Vectors of wrong size for quadcopter dynamics"

quadcopterDynamics :: (Floating a) =>
  Vector a -> -- Vector of disturbances
  Vector a -> -- Vector of states
  Vector a -> -- Vector of inputs
  Vector a    -- Vector of derivatives 
quadcopterDynamics = quadcopterParametrizedDynamics $ vector [1, 1, 1, 1, 9.82] 

-- | the gain matrix is refeered in the docs as `K`.
gainMatrix :: (Floating a) => Matrix a
gainMatrix = 
  vector [
    vector [66.924562, -0.000000, 0.000000, 15.237421, -0.000000, 0.000000, 0.000000, -15.288624, -0.000000, 0.000000, -9.923689, -0.000000],
    vector [-0.000000, 64.692684, 0.000000, -0.000000, 15.088983, -0.000000, -14.351152, 0.000000, -0.248452, -8.150969, 0.000000, 5.661805],
    vector [0.000000, -0.000000, 9.945378, 0.000000, -0.000000, 10.899601, 0.000000, -0.000000, -0.000000, 0.000000, -0.000000, -0.000000],
    vector [0.000000, 4.101449, 0.000000, 0.000000, 0.249255, 0.000000, -2.162173, -0.000000, -11.246851, -5.670719, 0.000000, -8.168167]
  ]

-- | simplest way to discretize the plant: make a Zero-Order Hold! if the sampling is fast,
-- The error should not be that bad
-- the equation implemented is x[k+1] = x[k] + ts*f(w[k], x[k], u[k])
quadcopterDynamicsZOH :: (Floating a) =>
  a ->        -- Sampling rate
  Vector a -> -- Vector of disturbances
  Vector a -> -- Vector of states
  Vector a -> -- Vector of inputs
  Vector a    -- Vector of next values 
quadcopterDynamicsZOH ts w x u = zipWithV (+) x $ mapV (ts*) $ quadcopterDynamics w x u  

-- | the implemented system is:
-- y[k+1] = y[k] + f(w[k], y[k], Ky[k])
controlledSystemSY :: (Floating a) =>
  (Signal (Vector a) -> Signal (Vector a) -> Signal (Vector a)) ->
  Vector a ->          -- Vector of initial state values
  a ->                 -- sampling rate
  Signal (Vector a) -> -- signal of references
  Signal (Vector a) -> -- signal of disturbances
  Signal (Vector a)    -- Signal of outputs
controlledSystemSY controlP x0 ts rSig wSig = ySig
  where
    ySig = zipWith3SY (quadcopterDynamicsZOH ts) wSig ySigDelayed uSig
    ySigDelayed = delaySY x0 ySig
    uSig = controlP rSig ySigDelayed

hQuadControl :: (Floating a)
             => Signal (Vector a) -> Signal (Vector a) -> Signal (Vector a)
hQuadControl rSig yD = gainP $ diffP rSig yD
  where diffP = zipWithSY (zipWithV (-))
        gainP = mapSY (dotVecMat (+) (*) gainMatrix)



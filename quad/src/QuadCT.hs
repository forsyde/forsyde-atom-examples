module QuadCT where

import ForSyDe.Atom.MoC
import ForSyDe.Atom.MoC.CT as CT
import ForSyDe.Atom.Skel.Vector as V

quadcopterParametrizedDynamics :: (Floating a) =>
  Vector a -> -- Vector of parameters
  Vector a -> -- Vector of disturbances
  Vector a -> -- Vector of states
  Vector a -> -- Vector of inputs
  Vector a    -- Vector of derivatives 
quadcopterParametrizedDynamics
  (iner_x:>iner_y:>iner_z:>m:>g:>Null)
  (tau_wx:>tau_wy:>tau_wz:>f_wx:>f_wy:>f_wz:>Null)
  (phi:>theta:>psi:>p:>q:>r:>u:>v:>w:>x:>y:>z:>Null)
  (tau_x:>tau_y:>tau_z:>f_t:>Null) =
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


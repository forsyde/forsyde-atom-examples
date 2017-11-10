In this section we model the  RC oscillator setup in \cref{fig:osc-circuit}. Despite its apparent simplicity, shows an interesting problem in CPS: how continuous systems react to discrete stimuli. This example was used in \cite{ungureanu18a}, and for a study on the theoretical implications of the chosen models, we strongly recommend reading this paper before going further. The source code for this section is found in the following module:

> module AtomExamples.Hybrid.RCOsc where

\begin{figure}[ht!]\centering
\includegraphics[width=.5\textwidth]{sawtooth-circuit}
\caption{RC oscillator setup}
\label{fig:osc-circuit}
\end{figure}

These are the dependencies that need to be included within this module:

> import ForSyDe.Atom                         -- general utilities
> import ForSyDe.Atom.MoC.CT   as CT          -- CT MoC library
> import ForSyDe.Atom.MoC.DE   as DE          -- DE MoC library
> import ForSyDe.Atom.MoC.SY   as SY          -- SY MoC library
> import ForSyDe.Atom.MoC.Time as T           -- utilities for functions of time
> import ForSyDe.Atom.MoC.TimeStamp (milisec) -- utilities for time stamps
> import ForSyDe.Atom.Utility.Plot            -- plotting utilities

The circuit in \cref{fig:osc-circuit} is characterized by two states: 1) $sw_1$ is closed and $sw_2$ open, equivalent to the situation where the capacitor C charges with VDD; 2) $sw_1$ is open and $sw_2$ is closed, equivalent to the situation where the capacitor C discharges to the ground through R. For the scope of this example, to keep the model simple and deterministic, we assume that $sw_1$ and $sw_2$ open/close alternatively at the same discrete time instants, there are no intermediary transitions, and we ignore the effects of discharge through switches. By applying Kirchhoff's laws and solving the differential equations, this is how we can characterize $V_O(t)$ for the charging/discharging cycles. 

> -- | RC constant.
> rc = 0.1
> 
> -- | V_O(t0,t) during the discharging. t0 is the instant when the switch occurred.
> voDischarge t0 = \t -> T.exp (-(t-t0) / rc)
> 
> -- | V_O(t0,t) during the charging. t0 is the instant when the switch occurred.
> voCharge    t0 = \t -> 1 - T.exp (-(t-t0) / rc)

Naturally, in \textsc{ForSyDe-Atom} we can model the oscillator in multiple ways, depending on what aspect we want to focus. Our first example models the RC oscillator as a Mealy finite state machine which embeds the continuous and discrete time semantics as defined in the \href{\moccturl}{\texttt{ForSyCt.Atom.MoC.CT}} library, like in \cref{fig:osc-atom1}. As such, we imply from the model that the switching of $sw_1$ and $sw_2$ is performed periodically after e certain $\tau$, inferred from the initial state of the \href{\moccturl}{\texttt{CT.mealy}} process. The configuration of the \href{\mocurl}{\texttt{mealy}} pattern ensures that 

\begin{figure}[ht!]\centering
\includegraphics[width=.5\textwidth]{atom-generator}
\caption{RC oscillator setup}
\label{fig:osc-atom1}
\end{figure}

> -- | RC oscillator model as CT FSM with discrete semantics inherent in the CT model.
> osc1 :: CT.Signal Rational -- ^ VDD as input signal
>      -> CT.Signal Rational -- ^ V_O as output signal
> osc1 = CT.mealy11 ns od (milisec 500, voCharge 0)
>   where
>     ns v _ = 1 + (-1 * v)
>     od     = (*)

> -- | Encodes the capacitor state
> data CState = Charging | Discharging

> -- | RC oscillator model as FSM which reacts to discrete impulses
> osc2 :: CT.Signal Time      -- ^ input signal
>      -> DE.Signal TimeStamp -- ^ control signal of discrete impulses
>      -> CT.Signal Time      -- ^ output signal
> osc2 s = CT.comb21 (*) s . embed (SY.mealy11 ns od Charging)
>   where
>     -- SY next state function
>     ns Charging    _  = Discharging
>     ns Discharging _  = Charging
>     -- SY output decoder function
>     od Charging    t0 = voCharge (time t0)
>     od Discharging t0 = voDischarge (time t0)
>     -- wrapper that embeds a SY process into a mixed DE/CT environment
>     embed p de        = let (t, sy) = DE.toSY de
>                         in DE.toCT $ SY.toDE t (p sy)


> s1 = CT.signal [(0,\_->2), (0.5,\_->0), (1,\_->1.5), (1.5,\_->0), (2,\_->1), (2.5,\_->0)] :: CT.Signal Rational
> s2 = CT.signal [(0,\_->2),(1,\_->1.5),(2,\_->1)]      :: CT.Signal Rational
> s3 = CT.signal [(0,\_->2),(1.2,\_->1.5),(2.3,\_->1)]  :: CT.Signal Rational
> s4 = DE.signal [(0,0), (1.2,1.2), (2.3,2.3)] :: DE.Signal TimeStamp
> dls = CT.unit (milisec 500, \t -> 1 - T.exp (-t / rc))

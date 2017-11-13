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

The circuit in \cref{fig:osc-circuit} is characterized by two states: 1) $sw_1$ is closed and $sw_2$ open, equivalent to the situation where the capacitor C charges with VDD; 2) $sw_1$ is open and $sw_2$ is closed, equivalent to the situation where the capacitor C discharges to the ground through R. For the scope of this example, to keep the model simple and deterministic, we assume that $sw_1$ and $sw_2$ open/close alternatively at the same discrete time instants, there are no intermediary transitions, and we ignore the effects of discharge through switches.

Let us analyze case 1) above. The circuit in \cref{fig:osc-circuit} becomes a RC integrator, where the input signal is applied to the resistance with the output taken across the capacitor. The amount of charge that is established across the plates of the capacitor is equal to the time domain integral of the current, like in eq.~\eqref{eq:cap-charge}. The rate at which the capacitor charges is directly proportional to the amount of the resistance and capacitance giving the time constant of the circuit like in  eq.~\eqref{eq:cap-const}. As the capacitors current can be expressed as the rate of change of charge, $Q$ with respect to time, we can express the charge at any instant of time like in eq.~\eqref{eq:cap-inst-charge}. Eq.~\eqref{eq:cap-inst-charge} brings together the previous equations and uses the instant voltage charge formula to obtain the final integral formula for $V_O$.
%
\begin{gather}
i_C(t) = C \frac{\partial V_{C(t)}}{\partial t} = \frac{V_{DD}}{R} \label{eq:cap-charge} \\
RC = R\frac{Q}{V}=R\frac{i \times T}{i \times R} = T \label{eq:cap-const}\\
i = \frac{\partial Q}{\partial t} \Rightarrow Q = \int i\ \partial t \label{eq:cap-inst-charge} \\
V_O = V_C = \frac{Q}{C} \stackrel{(3)}{=} \frac{1}{C} \int i\ \partial t \stackrel{(1)}{=} \frac{1}{C} \int \frac{V_{DD}}{R} \partial t = \frac{1}{RC} \int V_{DD} \partial t \label{eq:cap-vout}
\end{gather}

If an ideal step voltage pulse is applied, that is with the leading edge and trailing edge considered as being instantaneous, the voltage across the capacitor will increase for charging exponentially over time at a rate determined by eq.~\eqref{eq:rc-charge}. Similarly, in case 2) the circuit becomes an RC bridge where, assuming that C has been fully charged, it now discharges to the ground at a rate determined by eq.~\eqref{eq:rc-discharge}.
%
\begin{gather}
V_{O,\text{charge}}(t) = V_C(t) = V_{DD} \left( 1-e^{-\frac{t}{RC}} \right) \label{eq:rc-charge}\\
V_{O,\text{discharge}}(t) = V_C(t) = V_{DD} \left( e^{-\frac{t}{RC}} \right) \label{eq:rc-discharge}
\end{gather}

Translating eqs.~\eqref{eq:rc-charge} and \eqref{eq:rc-discharge} into \textsc{ForSyDe-Atom} Haskell code, we get the following, assuming \texttt{t0} is the moment where the switch occurred, and ignoring the factor of $V_{DD}$ (which is considered and scaled in the output decoder anyway).

> -- | RC time constant.
> rc = 0.1
> 
> -- | V_O(t0,t) during the discharging. t0 is the instant when the switch occurred.
> vcDischarge t0 = \t -> T.exp (-(t-t0) / rc)
> 
> -- | V_O(t0,t) during the charging. t0 is the instant when the switch occurred.
> vcCharge    t0 = \t -> 1 - T.exp (-(t-t0) / rc)

Naturally, in \textsc{ForSyDe-Atom} we can model the oscillator in multiple ways, depending on what aspect we want to focus. Our first example models the RC oscillator as a Mealy finite state machine which embeds the continuous and discrete time semantics as defined in the \href{\moccturl}{\texttt{ForSyCt.Atom.MoC.CT}} library, like in \cref{fig:osc1}. As such, we imply from the model that the switching of $sw_1$ and $sw_2$ is performed periodically after e certain $\tau$, inferred from the initial state of the \href{\moccturl}{\texttt{CT.mealy}} process. As such, the state machine is loaded with the voltage charging rule in eq.~\eqref{eq:rc-charge}, and a duration $\tau$. The configuration of the \href{\mocurl}{\texttt{mealy}} pattern ensures that at each multiple of $\tau$ the next state function \texttt{ns} will be performed, negating the state rule (i.e. the rate for $V_O$), basically translatig back and forth between eqs.~\eqref{eq:rc-charge} and \eqref{eq:rc-discharge}. As mentioned before, the output decoder \texttt{od} merely rescales $V_O$ with $V_{DD}$.

\begin{figure}[ht!]\centering
\includegraphics[width=.5\textwidth]{atom-generator}
\caption{Internal pattern of the initial RC oscillator setup}
\label{fig:osc1}
\end{figure}

> -- | RC oscillator model as CT FSM with discrete semantics inherent in the CT model.
> osc1 :: CT.Signal Rational -- ^ VDD as input signal
>      -> CT.Signal Rational -- ^ V_O as output signal
> osc1 = CT.mealy11 ns od (milisec 500, vcCharge 0)
>   where
>     ns v _ = 1 + (-1 * v)
>     od     = (*)

Plotting the output against an "arbitrary" $V_{DD}$, we get \cref{fig:osc1-plot}.

> -- | plotting configuration that will be used throughout this section
> cfg = defaultCfg {xmax=3, rate=0.05, labels=["V_{DD}","V_O"]}

> -- | example input for testing 'osc1'
> vdd1 = CT.signal [(0,\_->2),(1,\_->1.5),(2,\_->1)] :: CT.Signal Rational
> 
> -- | plotting the response of 'osc1'
> plot1 = plotGnu $ prepareL cfg $ [vdd1, osc1 vdd1]

\begin{figure}[ht!]\centering
\input{input/sig-osc1-latex}
\caption{Response of \texttt{osc1}}
\label{fig:osc1-plot}
\end{figure}

The model for \texttt{osc1}, although strikes out as simple and elegant, is by all means limited. In the following paragraphs we will address these limitations one at a time, and try find solutions that overcome them in order to include more realistic or at least a family of behaviors correctly covering classes of (increasing) non-determinism.

\cite{Lee17} argues that determinism is an attribute of the model, and it is dependent on what we consider as inputs and outputs. As such, the model \texttt{osc1} in \cref{fig:osc1} is a deterministic model for the circuit in \cref{fig:osc-circuit} and the output in \cref{fig:osc1-plot} is the correct response in the following conditions:

\begin{itemize}
\item the changes in $V_{DD}$ happen at multiple of $\tau$. If a changes occur anywhere in between, the response will be shown, but it will not describe the RC circuit in a realistic manner, as we will see shortly.
\item the time constant follows roughly the rule $5RC\leq\tau$ where the chosen $\tau$ is a part of the initial state of the Mealy state machine. This says that the discharging occurrs when the capacitor is charged at least $99.3\%$ and vice-versa, according to eqs.~\eqref{eq:rc-charge} and \eqref{eq:rc-discharge}.
\item $\tau>0$. $\tau=0$ would render the system as non-causal and would manifest Zeno behavior. In practical terms, this is the equivalent of the simulation being stuck and not advancing time.
\end{itemize}

Another property (or limitation, depending on what your intentions are) is that the switching of $sw_1$ and $sw_2$ cannot be controlled and is a property of the Mealy machine. This switching is inferred by $\tau$ which sets the (discrete) period of these events. Let us change that by giving the possibility to control the state of the capacitor as charging/discharging through a signal of discrete events. A system such as the one we propose implies some subtle changes in the modelling which require a deeper understanding on the underlying MoCs. First of all, we still require a stateful process (a state machine) which captures the notion of working modes, but which reacts to a state change instantaneously. But this implies that $\tau = 0$ which, as said above, would lead to Zeno behavior. On the other hand, the particular behavior required is described precisely by \emph{synchronous reactive} MoC, where the response of a system is performed in "zero time".

Continuing to adhere to the school of thought of \cite{Lee17}, where the merit of the modeler lies in choosing the right modeling paradigm for the right problem\footnote{Lee argues that the cost we pay in the loss of determinism is a property of the modeling framework, and \emph{not} of the model itself.}, we choose to model the above described system as a synchronous reactive (SY) state machine wrapped inside a DE/CT environment like in ... . 



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
>     od Charging    t0 = vcCharge (time t0)
>     od Discharging t0 = vcDischarge (time t0)
>     -- wrapper that embeds a SY process into a mixed DE/CT environment
>     embed p de        = let (t, sy) = DE.toSY de
>                         in DE.toCT $ SY.toDE t (p sy)


> s4 = DE.signal [(0,0), (1.2,1.2), (2.3,2.3)] :: DE.Signal TimeStamp

> s1 = CT.signal [(0,\_->2), (0.5,\_->0), (1,\_->1.5), (1.5,\_->0), (2,\_->1), (2.5,\_->0)] :: CT.Signal Rational
> s2 = CT.signal [(0,\_->2),(1,\_->1.5),(2,\_->1)]      :: CT.Signal Rational
> s3 = CT.signal [(0,\_->2),(1.2,\_->1.5),(2.3,\_->1)]  :: CT.Signal Rational
> s4 = DE.signal [(0,0), (1.2,1.2), (2.3,2.3)] :: DE.Signal TimeStamp
> dls = CT.unit (milisec 500, \t -> 1 - T.exp (-t / rc))

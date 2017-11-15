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
> cfg = defaultCfg {xmax=3, rate=0.01}

> -- | example input for testing 'osc1'
> vdd1 = CT.signal [(0,\_->2),(1,\_->1.5),(2,\_->1)] :: CT.Signal Rational
> 
> -- | plotting the response of 'osc1'
> plot1 = plotGnu $ prepareL cfg {labels=["V_{DD}","V_O"]} $ [vdd1, osc1 vdd1]

\begin{figure}[ht!]\centering
\input{input/sig-osc1-latex}
\caption{Response of \texttt{osc1}}
\label{fig:osc1-plot}
\end{figure}

The model for \texttt{osc1}, although strikes out as simple and elegant, is by all means limited. In the following paragraphs we will address these limitations one at a time, and try find solutions that overcome them in order to include more realistic or at least a family of behaviors correctly covering classes of (increasing) non-determinism.

\cite{Lee17} argues that determinism is an attribute of the model, and it is dependent on what we consider as inputs and outputs. As such, the model \texttt{osc1} in \cref{fig:osc1} is a deterministic model for the circuit in \cref{fig:osc-circuit} and the output in \cref{fig:osc1-plot} is the correct response in the following conditions:

\begin{itemize}
\item the changes in $V_{DD}$ happen at multiples of $\tau$. If a changes occur at any other time the response will be shown, but it will not describe the RC circuit in a realistic manner, as we will see shortly.
\item the time constant follows roughly the rule $5RC\leq\tau$ where the chosen $\tau$ is a part of the initial state of the Mealy state machine. This says that the discharging occurrs when the capacitor is charged at least $99.3\%$ and vice-versa, according to eqs.~\eqref{eq:rc-charge} and \eqref{eq:rc-discharge}.
\item $\tau>0$. $\tau=0$ would render the system as non-causal and would manifest Zeno behavior. In practical terms, this is the equivalent of the simulation being stuck and not advancing time.
\end{itemize}

Another property (or limitation, depending on what your intentions are) is that the switching of $sw_1$ and $sw_2$ cannot be controlled and is a property of the Mealy machine. This switching is inferred by $\tau$ which sets the (discrete) period of these events. Let us change that by giving the possibility to control the state of the capacitor as charging/discharging through a signal of discrete events. A system such as the one we propose implies some subtle changes in the modelling which require a deeper understanding on the underlying MoCs. First of all, we still require a stateful process (a state machine) which captures the notion of working modes, but which reacts to a state change instantaneously. But this implies that $\tau = 0$ which, as said above, would lead to Zeno behavior. On the other hand, the particular behavior required is described precisely by \emph{synchronous reactive} MoC, where the response of a system is performed in "zero time".

Continuing to adhere to the school of thought of \cite{Lee17}, where the merit of the modeler lies in choosing the right modeling paradigm for the right problem\footnote{Lee argues that the cost we pay in the loss of determinism is a property of the chosen modeling framework, and \emph{not} of the model itself.}, we choose to model the above described system as a synchronous reactive (SY) state machine wrapped inside a DE/CT environment like in \cref{fig:osc2}. As such, we should note a few particularities of this model:

\begin{itemize}
\item in CT the carried values are implicit functions of time, i.e. they carry time semantics. In DE and SY, the time semantics make no sense, thus the same functions of time are explicit (where \texttt{Time} itself is just a data type $\in V$). Therefore when converting $\mathcal{S}_{CT}(\alpha) \mapsto \mathcal{S}_{DE}(t \to \alpha)$ and vice-versa $\mathcal{S}_{DE}(t \to \alpha) \mapsto \mathcal{S}_{CT}(\alpha)$.
\item in SY tags are useless, therefore DE tags and values are split into two separate SY signals upon conversion. This way we can easily recreate the DE signal without loss of information. So upon conversion $\mathcal{S}_{DE}(\alpha) \mapsto \mathcal{S}_{SY}(t) \times \mathcal{S}_{SY}(\alpha)$ and vice-versa $\mathcal{S}_{SY}(t) \times \mathcal{S}_{SY}(\alpha) \mapsto \mathcal{S}_{DE}(\alpha)$.
\item the discrete control signal $S_{\text{control}}$, carries nothing, and it is used only for the timestamps generated by its tags, i.e. for generating $\mathcal{S}_{SY}(t)$. These timestamps are further used by the \texttt{od} function to determine the time when the switch occurred \texttt{t0} in the formulas for $V_O$ in eqs.~\eqref{eq:rc-charge} and \eqref{eq:rc-discharge}.
\end{itemize}
%
\begin{figure}[ht!]\centering
\includegraphics{atom-osc2}
\caption{RC oscillator model which reacts to a discrete control signal. Shapes decorating signals suggest the type of carried tokens: circles = scalars; squares = functions}
\label{fig:osc2}
\end{figure}

Like in the model from \cref{fig:osc1}, the model for \texttt{osc2} in \cref{fig:osc2} scales the output with $V_{DD}$ through a combinational CT process. The next state decoder function $ns$ does not manipulate the rule for $V_C$ anymore, but rather switches between the states \texttt{Charge} and \texttt{Discharge}, and the output decoder $od$ selects the proper $V_C$ rule from eq.~\eqref{eq:rc-charge} or eq.~\eqref{eq:rc-discharge} respectively, based on the current state.

> -- | Encodes the capacitor state
> data CState = Charging | Discharging

We encode the capcitor state (i.e. the states of $sw_1$ and $sw_2$) through the \texttt{CState} data type. Thus the code for \cref{fig:osc2} is:

> -- | RC oscillator model as FSM which reacts to discrete impulses
> osc2 :: CT.Signal Rational  -- ^ VDD input signal
>      -> DE.Signal ()        -- ^ control signal of discrete impulses
>      -> CT.Signal Rational  -- ^ output signal
> osc2 s = CT.comb21 (*) s . embed (SY.mealy11 ns od Charging)
>   where
>     -- SY next state function
>     ns Charging    _  = Discharging
>     ns Discharging _  = Charging
>     -- SY output decoder function
>     od Charging    t0 = vcCharge (time t0)
>     od Discharging t0 = vcDischarge (time t0)
>     -- wrapper that embeds a SY process into a mixed DE/CT environment
>     embed p de        = let (t, _) = DE.toSY de
>                         in DE.toCT $ SY.toDE t (p t)

%$

Now let us create two situations to test \texttt{osc2}. The control signal \texttt{sCtrl} injects events at timestamps 0, 0.6, 1.4, 2.3 and 2.8, causing the SY state machine to react each time changing its state from \texttt{Charge} to \texttt{Discharge} and vice-versa. The first $V_{DD}$ input \texttt{vdd21} is mirroring an ``ideal case'', when changes occur at time instants where switching happens, meaning that it does not affect the evolution of the $V_O$ rule. On the contrary, \texttt{vdd22} comes at arbitrary times, thus affecting the output in a way that is unrealistic, i.e. $V_O$ changes values abruptly and instantaneously, which strays away from the acceptable behavior of a capacitor. This can be seen in \cref{fig:osc2-plot}.

> -- | Signal of discrete events. Carries nothing, it is used only for the time stamps.
> sCtrl = DE.signal [(0,()),(0.6,()),(1.4,()),(2.3,()),(2.8,())] :: DE.Signal ()
> 
> -- | example input for testing 'osc2'
> vdd21 = CT.signal [(0,\_->2),(1.4,\_->1.5),(2.8,\_->1)] :: CT.Signal Rational
> vdd22 = CT.signal [(0,\_->1),(0.8,\_->2),(1.6,\_->1.5)] :: CT.Signal Rational
> 
> -- | plotting the example responses of 'osc2'
> plot21 = plotGnu $ prepareL cfg {labels=["V_{DD}","V_O"]} $ [vdd21, osc2 vdd21 sCtrl]
> plot22 = plotGnu $ prepareL cfg {labels=["V_{DD}","V_O"]} $ [vdd22, osc2 vdd22 sCtrl]

\begin{figure}[ht!]\centering
\begin{minipage}{.47\textwidth}
\scalebox{.5}{\input{input/sig-osc2-latex}}
\end{minipage}
\begin{minipage}{.47\textwidth}
\scalebox{.5}{\input{input/sig-osc2-latex-1}}
\end{minipage}
\caption{Response of \texttt{osc2}}
\label{fig:osc2-plot}
\end{figure}

The second case in \cref{fig:osc2-plot} can be explained easily if we consider the fact that $V_O$ itself is the result of a statically pre-calculated function of time. There is no notion of feedback response to the continuous inputs, the only feedback is synchronous reactive for \texttt{osc2} and even \texttt{osc1}. In other words any change on the input will affect how the output ``looks like'', but it will not affect the continuous behavior which, as said, is pre-calculated. In order to influence the continuous behavior, some sort of continuous feedback is necessary, which is usually non-causal, thus uncomputable. Without going too much into detail we can say that in order to model a realistic behavior of the capacitor response in $V_O$, we need to embed an ordinary differential equation (ODE) solver within a synchronous reactive state machine\footnote{theoretical implications will be analyzed in the upcoming journal publications}, which models precisely eq.~\eqref{eq:cap-vout}.

\begin{figure}[ht!]\centering
\includegraphics[width=.3\textwidth]{rc-circuit}
\includegraphics[width=.5\textwidth]{rc-block}
\caption{RC bridge: circuit (left); block diagram based on eq.~\eqref{eq:cap-vout} (right)}
\label{fig:rc-circuit}
\end{figure}
%
\begin{gather}
  \int_{t_0}^{t_0+h}f(t,y(t)) \partial t \approx h f(t_0,y(t_0))\label{eq:euler}\\
  \dot{y}_n = \frac{hRC}{h+RC} \left(\frac{1}{RC} y_n + \frac{1}{h} y_{n-1}\right)\label{eq:rc-euler}
\end{gather}

First let us model a simple RC bridge like in \cref{fig:rc-circuit} which acts like a low-pass filter, and acts according to eq.~\eqref{eq:cap-vout}. As mentioned, we model this circuit as a SY state machine embedded within a CT environment. Why a state machine? Because the circuit itself, due to the capacitor, is a memory system, i.e. its output is dependent on its history as well as inputs. The previous "history" at the start of simulation is encoded inside the initial state. The next state decoder itself needs to "feed-through" the input and mirror the behavior of the block diagram \cref{fig:rc-circuit}. On the other hand, this block diagram shows a non-causal system, which as such is uncomputable, and needs to be transformed into a solvable form. As per the writing of this report, \textsc{ForSyDe-Atom}\footnote{version 0.2.2} did not provide generic ODE solvers, thus for didactic purpose we write the following numerical solver for our RC circuit in \cref{fig:rc-circuit} using Euler's trapezoidal method eq.~\eqref{eq:euler}, by substituting by hand eq.~\eqref{eq:cap-vout} with its feed-forward version in eq.~\eqref{eq:rc-euler}:

> -- | ODE solver for a simple RC low-pass filter using Euler's method
> euler :: TimeStamp          -- ^ time step for the solver precision 
>       -> (Time -> Rational) -- ^ the input function being integrated
>       -> Rational           -- ^ the "history" of the integral at t0
>       -> TimeStamp          -- ^ t0
>       -> Time -> Rational   -- ^ a function of time
> euler step f p t0 t = iterate p t0
>   where
>     h = time step
>     -- by-hand substitution of eq.(4) using the trapezoidal rule
>     calc vp v = (h * rc)/(h + rc) * (1/rc * v + 1/h * vp)
>     -- loop which calculates the integral step-wise from t0 to t
>     iterate st ti
>       | t < time ti = st
>       | otherwise   = iterate (calc st $ f (time ti)) (ti + step)

%$
As said earlier, we model the RC circuit in \cref{fig:rc-circuit} by including the \texttt{euler} solver into a feed-through state machine (see the \href{\mocurl}{\texttt{state}} pattern) like in \cref{fig:atom-rc}. Like for \texttt{osc2}, the timestamps resulted after splitting the tags from values when interfacing between DE and SY are used for determining the $t_0$s for each new incoming event. The solver inputs functions of time and outputs functions of time (i.e. the solver itself is the output).
\\

\begin{figure}[ht!]\centering
\includegraphics[]{atom-rcfilter}
\caption{\textsc{ForSyDe-Atom} model of the RC bridge in \cref{fig:rc-circuit}}
\label{fig:atom-rc}
\end{figure}

> rcfilter :: CT.Signal Rational -> CT.Signal Rational
> rcfilter s
>   = let (ts, sy) = DE.toSY $ CT.toDE s
>         out      = SY.state21 ns (\_->0) ts sy
>         ns p t s = euler 0.01 s (p (time t)) t
>     in DE.toCT $ SY.toDE ts out

Testing the filter against a square wave signal, we get the response plotted in \cref{fig:rcfilter-plot}. As can be clearly seen, the behavior is the right one and it reacts correctly to the inputs, taking unto account the current state of the system, i.e. its history, and it is a \emph{continuous} signal in the true sense of the word.

> -- | square wave signal for testing 'rcfilter'
> vi3 = CT.signal [(0,\_->2), (0.3,\_->0), (1,\_->1.5), (1.5,\_->0), (1.7,\_->1), (2.5,\_->0)] :: CT.Signal Rational
> 
> -- | plotting the example response of 'rcfilter'
> plot31 = plotGnu $ prepareL cfg {labels=["V_I","V_O"]} $ [vi3, rcfilter vi3]

\begin{figure}[ht!]\centering
\input{input/sig-rcfiler-latex}
\caption{Response of \texttt{rcfilter}}
\label{fig:rcfilter-plot}
\end{figure}

Now let us modify \texttt{osc2} from \cref{fig:osc2} to mirror the correct behavior of the circuit in \cref{fig:osc-circuit}. Seems to it that there is not much to do, as \texttt{rcfilter} already responds correctly to any input. On the other hand the RC oscillator as represented in  \cref{fig:osc-circuit} admits as inputs both $V_{DD}$ and the control signal for $sw_1$ and $sw_2$. To correctly model that in \textsc{ForSyDe-Atom} we need to separate the FSM which controls the state of the capacitor as charging or discharging, which in turn will generate $V_I$. We do that like in \cref{fig:osc4}.

> -- | ODE-based RC oscillator model
> osc4 :: CT.Signal Rational  -- ^ VDD input signal
>      -> DE.Signal ()        -- ^ control signal of discrete impulses
>      -> CT.Signal Rational  -- ^ output signal
> osc4 vdd ctl
>   = let -- generator for the switch state variable
>         swState = DE.embedSY11 (SY.stated11 swF Charging) ctl
>         swF Charging    _  = Discharging
>         swF Discharging _  = Charging
>         -- transforms VDD into VI for the RC filter
>         vddSwitched        = DE.comb21 vddF swState $ CT.toDE vdd
>         vddF Charging    v = v
>         vddF Discharging _ = \_->0
>         -- state machine with ODE solver modeling an RC filter
>         vOut        = embed (SY.state21 nsEU (\_->0)) vddSwitched
>         nsEU p t s  = euler 0.01 s (p $ time t) t
>         -- custom wrapper that embeds a SY tag-aware process into a DE environment
>         embed p de  = let (t, v) = DE.toSY de
>                       in SY.toDE t (p t v)  
>     in DE.toCT vOut

\begin{figure}[ht!]\centering
\includegraphics[]{atom-osc4}
\caption{\textsc{ForSyDe-Atom} model of the RC oscillator described by \texttt{osc4}}
\label{fig:osc4}
\end{figure}

Testing \texttt{osc4} against the same inputs as \texttt{osc2} in \cref{fig:osc2-plot}, we get the response plotted in \cref{fig:osc4-plot}, which is now the correct behavior of the RC circuit with respect to its inputs. As expected, the output describes correctly the state and history of the capacitor.

> plot41 = plotGnu $ prepareL cfg {labels=["V_{DD}","V_O"]} $ [vdd22, osc4 vdd22 sCtrl]

\begin{figure}[ht!]\centering
\input{input/sig-osc4-latex}
\caption{Response of \texttt{osc4}}
\label{fig:osc4-plot}
\end{figure}

We have shown three different models of an RC oscillator circuit represented in \cref{fig:osc-circuit} at different levels of complexity, and a model of an RC bridge represented in \cref{fig:rc-circuit}. The fact that they are different does not mean that either is ``more correct/incorrect'' than the other. Either of them might very well be treated as ``correct'' depending on what we consider or not the acceptable inputs (note that we have not defined them on purpose). As expected, the more we consider the inputs as sources of non-determinism, the more complex our model needs to be in order to cover ``special'' cases. As you might guess already, this comes at a severe cost of run-time performance.

Let us briefly measure this cost in performance between the four presented models. For this, we consider two situations:

\begin{itemize}
\item[\textbf{Experiment 1}] we need to find out $V_O$ at $t=2.8$ seconds.
\item[\textbf{Experiment 2}] we need to sample $V_O$ for the whole period $t=[0,3]$ seconds, with a precision of 50 milliseconds.
\end{itemize}

We consider the same input scenarios for all 4 models:

> -- | plotting/sampling configuration for performance testing
> cfgTest = defaultCfg {xmax=3, rate=0.005}
> -- | VDD input for performance testing
> vddTest = CT.signal [(0,\_->2),(1,\_->1.5),(2,\_->1)] :: CT.Signal Rational
> -- | VI input for performance testing of the RC filter model
> viTest = CT.signal [(0,\_->2),(0.5,\_->0),(1,\_->1.5),(1.5,\_->0),(2,\_->1),(2.5,\_->0)] :: CT.Signal Rational
> -- | Switch control signal for performance testing
> ctlTest = DE.signal [(0,()),(0.5,()),(1,()),(1.5,()),(2,()),(2.5,())] :: DE.Signal ()

First, let us test the performance of each model in case of one evaluation point. This can be easily found out in \texttt{ghci} by adding the option \texttt{:set +s} during an interpreter session. For showing the precision of the model calculation, we convert the output rational numbers into floating point representation.

< λ> :set +s
< λ> fromRational $ osc1 vddTest         `CT.at` 2.8
< 4.9787192469339395e-2
< (0.01 secs, 398,792 bytes)
< λ> fromRational $ osc2 vddTest ctlTest `CT.at` 2.8
< 4.9787192469339395e-2
< (0.01 secs, 385,952 bytes)
< λ> fromRational $ rcfilter viTest      `CT.at` 2.8
< 5.169987618408467e-2
< (0.08 secs, 34,044,128 bytes)
< λ> fromRational $ osc4 vddTest ctlTest `CT.at` 2.8
< 5.169987618408467e-2
< (0.07 secs, 34,047,720 bytes)

\begin{table}[ht!]
  \centering
  \begin{tabular}{r||c|c||c|c}
    \multirow{ 2}{*}{Model} & \multicolumn{2}{c||}{\textbf{Experiment 1}} & \multicolumn{2}{c}{\textbf{Experiment 2}} \\ 
    & time (s) & memory (MB) & time (s) & memory (MB) \\ \midrule
    \texttt{osc1}     & 0.01 & 0.4 & 0.09 & 23 \\
    \texttt{osc2}     & 0.01 & 0.4 & 0.09 & 18 \\
    \texttt{rcfilter} & 0.08 & 34  & 5.04 & 1930 \\
    \texttt{osc4}     & 0.07 & 34  & 5.56 & 1930
  \end{tabular}
  \caption{Experimental results for testing the RC models}
  \label{tab:rc-exp}
\end{table}

The experimental results on an computer with Intel® Core™ i7-3770 CPU @ 3.40GHz $\times$ 8 cores, and 31,4 GiB RAM are shown in \cref{tab:rc-exp}. As expected, \texttt{osc1} and \texttt{osc2} perform in almost negligible time for both experiments due to lazy evaluation which performs computation only at the requested evaluation point. However, the lazy evaluation is costly in terms of run-time memory, fact noticed especially for \texttt{rcfiler} and \texttt{osc4} due to the fact that intermediate structures need to be stored before evaluating. The complexity of \texttt{rcfilter} and \texttt{osc4} are seen both in the execution time and in the memory consumption. Apart from the cost in performance, model fidelity for unknown inputs came also with a high price in loss of precision due to chained numerical computation, fact seen from the evaluation results of \textbf{Experiment 1} in the interpreter listing above. Choosing a better solver than \texttt{euler}, e.g. a Runge-Kutta solver, or even better, a symbolic solver, could improve both performance and precision, but that is out of the scope of this report. Another, rather surprising fact is that \texttt{osc2} performs slightly better than \texttt{osc1}, probably to the lack of tag calculus in the SY domain, i.e. tags are mainly passed untouched between interfaces, whereas calculations are performed in a synchronous reactive manner on values only.


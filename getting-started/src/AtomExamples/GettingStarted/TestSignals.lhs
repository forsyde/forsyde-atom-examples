\subsection{Test input signals}
\label{sec:getting-started:test-signals}

In the following examples we will use a set of test signals defined in the following module, which is also re-exported by \texttt{AtomExamples.GettingStarted} (i.e. you don't need to import it):

> module AtomExamples.GettingStarted.TestSignals where

The test signals need to define tag systems belonging to different MoCs. Each MoC has an own dedicated module under \href{\contentsurl}{\texttt{ForSyDe.Atom.MoC}} which defines atoms, patterns, types and utilities.  Just like in the previous section, we need to import the needed modules. This time we name them using short aliases, to disambiguate between the different DSL items, often sharing the same name, but defined in different places. 
 
> import ForSyDe.Atom.ExB.Absent (AbstExt(..))
> import ForSyDe.Atom.MoC.SY          as SY
> import ForSyDe.Atom.MoC.DE          as DE
> import ForSyDe.Atom.MoC.CT          as CT
> import ForSyDe.Atom.MoC.SDF         as SDF
> import ForSyDe.Atom.MoC.Time        as T
> import ForSyDe.Atom.MoC.TimeStamp   as Ts
> import ForSyDe.Atom.Skeleton.Vector as V
> import ForSyDe.Atom.Utility.Plot

Let the signals \texttt{sdf1}--\texttt{sdf4} denote four \href{\mocsdfurl}{SDF} signals, i.e. sequences of events. Instead of using the \href{\mocsdfurl}{\texttt{signal}} utility, we use \href{\mocsdfurl}{\texttt{readSignal}} which reads a string, tokenizes it and converts it to a SDF signal. This utility function needs to be "steered" into deciding which data type to output so in order to specify the type signature we use the inline Hakell syntax \texttt{name = definition :: type}. All events, although extended, are present.

> sdf1 = SDF.readSignal "{ 1, 1, 1, 1, 1, 1}" :: SDF.Signal (AbstExt Int)
> sdf2 = SDF.readSignal "{-1, 1,-1, 1,-1, 1}" :: SDF.Signal (AbstExt Int)
> sdf3 = SDF.readSignal "{ 0, 0, 1, 1, 0   }" :: SDF.Signal (AbstExt Int)
> sdf4 = SDF.readSignal "{-1,-1,-1,-1,-1   }" :: SDF.Signal (AbstExt Int)

Similarly, let the signals \texttt{sy1}--\texttt{sy4} denote four \href{\mocsyurl}{SY} signals, i.e. all events are synchronized with each other. We use the SY version of \href{\mocsyurl}{\texttt{readSignal}}, also "steered" by declaring the types inline, and all events are also present.

> sy1 = SY.readSignal "{ 1, 1, 1, 1, 1, 1}" :: SY.Signal (AbstExt Int)
> sy2 = SY.readSignal "{-1, 1,-1, 1,-1, 1}" :: SY.Signal (AbstExt Int)
> sy3 = SY.readSignal "{ 0, 0, 1, 1, 0   }" :: SY.Signal (AbstExt Int)
> sy4 = SY.readSignal "{-1,-1,-1,-1,-1   }" :: SY.Signal (AbstExt Int)

For the \href{\mocdeurl}{DE} signals \texttt{de1}--\texttt{de4} we need to specify for each event an explicit tag (i.e. timestamp), as required by the DE tag system. For this, the DE version of \href{\mocdeurl}{\texttt{readSignal}} reads each event using the syntax \texttt{value@timestamp}. Needless to say, all events are also present.

> de1 = DE.readSignal "{ 1@0                                   }":: DE.Signal (AbstExt Int)
> de2 = DE.readSignal "{-1@0, 1@0.7,-1@1.4, 1@2.1,-1@2.8, 1@3.5}":: DE.Signal (AbstExt Int)
> de3 = DE.readSignal "{ 0@0,        1@1.4,        0@2.8       }":: DE.Signal (AbstExt Int)
> de4 = DE.readSignal "{-1@0                                   }":: DE.Signal (AbstExt Int)

Let \texttt{ct1}--\texttt{ct4} denote four \href{\moccturl}{CT} signals. As the events in a CT signal are themselves continuous functions of time, we cannot specify them as mere strings, thus we cannot use a \texttt{readSignal} utility any more. This time we will use the CT version of the \href{\moccturl}{\texttt{signal}} utility, where each event is specified as a tuple \texttt{(timestamp, $f(t)$)}, and can be considered as a continuous sub-signal. For representing time we use an alias \texttt{Time} for \href{https://hackage.haskell.org/package/base-4.10.0.0/docs/Data-Ratio.html}{\texttt{Rational}}, defined in the \href{\moctimeurl}{\texttt{ForSyDe.Atom.MoC.Time}}. This module also contains utility functions of time, such as the constant function \href{\moctimeurl}{\texttt{const}} or the sine \href{\moctimeurl}{\texttt{sin}}. We define local functions to wrap the type returned by a CT subsignal into an \texttt{AbstExt} type.

> pconst = T.const . Prst
> ct1 = CT.signal [(0,pconst 1)]                               :: CT.Signal (AbstExt Time)
> ct2 = CT.signal [(0,Prst . (\t -> T.sin (T.pi * t)))]        :: CT.Signal (AbstExt Time)
> ct3 = CT.signal [(0,pconst 0),(1.4,pconst 1),(2.8,pconst 0)] :: CT.Signal (AbstExt Time)
> ct4 = CT.signal [(0,pconst (-1))]                            :: CT.Signal (AbstExt Time)

Finally, we need to bundle these signals into vectors of signals, to feed into the \texttt{toy} system from \cref{{fig:subfig1}} and eq.~\eqref{eq:case1}. For this purpose we pass the four signals of each MoC as a list to the \href{\skelvecurl}{\texttt{vector}} utility.

> vsdf = V.vector [sdf1, sdf2, sdf3, sdf4] :: V.Vector (SDF.Signal (AbstExt Int))
> vsy  = V.vector [ sy1,  sy2,  sy3,  sy4] :: V.Vector ( SY.Signal (AbstExt Int))
> vde  = V.vector [ de1,  de2,  de3,  de4] :: V.Vector ( DE.Signal (AbstExt Int))
> vct  = V.vector [ ct1,  ct2,  ct3,  ct4] :: V.Vector ( CT.Signal (AbstExt Time))

Now we need to create for each MoC the vectors with the initial states for the Moore machines, i.e. $\SkelVec{i}$ from \cref{tab:application}. For SDF, SY and DE we are also making use of the fact that the defined data types are \href{https://hackage.haskell.org/package/base-4.10.0.0/docs/Text-Read.html}{Read}able. The data types that we need within the vectors are in accordance to the \texttt{moore} process constructor helpers defined in each module, so be sure to check the \href{\contentsurl}{online API documentation} to understand why we need those particular types. For example, SDF requires a partition (list) of values as initial states whereas DE apart from a value it requires also the duration of the first event. For the CT vector, as before, we cannot read functions as string, so we use the \href{\skelvecurl}{\texttt{vector}} utility.  \texttt{ict} also shows the usage of the \href{\moctstampurl}{\texttt{milisec}} utility which converts an integer into a timestamp.

> isdf = read "<[-1],[ 1],[-1],[ 1]>" :: V.Vector [AbstExt Int]
> isy  = read "<(-1),  1, (-1),  1 >" :: V.Vector (AbstExt Int)
> ide  = read "<(1,-1),(1.4, 1),(1.0,-1),(1.4, 1)>"
>                                     :: V.Vector (TimeStamp, AbstExt Int)
> ict  = V.vector [
>   (Ts.milisec 1000, pconst (-1)),
>   (Ts.milisec 1400, pconst   1 ),
>   (Ts.milisec 1000, pconst (-1)),
>   (Ts.milisec 1400, pconst   1 )]   :: V.Vector (TimeStamp, Time -> AbstExt Time)

For the polymorphic instance in \cref{sec:getting-started:poly-instance} we need to provide the initial states as wrapped in signals, so we create unit signals:

> sisdf = SDF.signal <$> isdf
> sisy  = SY.unit    <$> isy
> side  = DE.unit    <$> ide
> sict  = CT.unit    <$> ict

Finally, let us instantiate some plotting utilities, to test the different signals throughout the experiments:

> plot  until lbls =    plotGnu . prepare defaultCfg {xmax=until, labels=lbls, rate=0.01}
> latex until lbls =  plotLatex . prepare defaultCfg {xmax=until, labels=lbls, rate=0.01}
> plotV  until lbls =    plotGnu . prepareV defaultCfg {xmax=until, labels=lbls, rate=0.01}
> latexV until lbls =  plotLatex . prepareV defaultCfg {xmax=until, labels=lbls, rate=0.01}

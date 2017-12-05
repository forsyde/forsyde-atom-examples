The final section of this report introduces the reader to constructing custom patterns in \textsc{ForSyDe-Atom}. Up until now we have been using patterns which were pre-defined as compositions of atoms. Atoms are primitive, indivizible building blocks capturing the most basic semantics in each layer.

> {-# LANGUAGE PostfixOperators #-}

The code for this section is found in the following module, which is \emph{not} re-exported, i.e. needs to be manually imported.

> module AtomExamples.GettingStarted.CustomPattern where

For this exercise, we will create a custom \texttt{comb} pattern with 5 inputs and 3 outputs, as a process constructor in the MoC layer. We will test this pattern with a set of SY and a set of DE input signals, thus we need to import the following modules: 

> import ForSyDe.Atom
> import ForSyDe.Atom.MoC
> import ForSyDe.Atom.MoC.SY as SY
> import ForSyDe.Atom.MoC.DE as DE

The best way to start building your own patterns is to study the source code for the existing patterns and see how they are made. If you don't want to dig into the source code of \textsc{ForSyDe-Atom}, there is a link in the \href{\mocurl}{API documentation} for each exported element, as suggested in \cref{fig:API-screenshot}. 

\begin{figure}[h!]\centering
\includegraphics[width=.8\linewidth]{API-screenshot.png}
\caption[Screenshot from online API documentation]{Screenshot from the API documentation. The link to the source code is marked with a red rectangle}
\label{fig:API-screenshot}
\end{figure}

Studying the \texttt{comb22} pattern, you can see that it is defined in terms of the \texttt{lift} and \texttt{sync} atoms which are represented by the infix operators \href{\mocurl}{\texttt{-.-}} and \href{\mocurl}{\texttt{-*-}} respectively, and the \texttt{unzip} utility represented by the postfix operator \href{\mocurl}{\texttt{-*<}}. \texttt{lift} and \texttt{sync} are atoms becuse they capture an interface for exeucution semantics, whereas \texttt{unzip} is just a utility because it is merely a type traversal which alters the structure of data types and rebuilds it to describe "signals of events carrying values". 

Considering the applicative nature of the \texttt{-.-} and \texttt{-*-} atoms, the \texttt{comb} pattern with 5 inputs and 3 outputs can be written as the mathematical formula below. This one-liner tells that function \texttt{f} is "lifted" into the MoC domain, and applied to the five input signals which are synchronized. The \texttt{-*<<} postfix operator then "unzips" the resulting signal of triples into three synchronized signals of values. 
The applicative mechanism explained in the previous paragraph is depicted in \cref{fig:custom-comb}.

> comb53 f s1 s2 s3 s4 s5
>   = (f -.- s1 -*- s2 -*- s3 -*- s4 -*- s5 -*<<)

\begin{figure}[h!]\centering
\includegraphics[width=.6\linewidth]{comb}
\caption{Composition of atoms forming the \texttt{comb} pattern}
\label{fig:custom-comb}
\end{figure}

If we want to restrict the pattern to one specific MoC, then we must mention this in the type signature we associate it with, like in the example below.

> comb53SY :: (a1 -> a2 -> a3 -> a4 -> a5 -> (b1,b2,b3))
>          -> SY.Signal a1    -- ^ input signal
>          -> SY.Signal a2    -- ^ input signal
>          -> SY.Signal a3    -- ^ input signal
>          -> SY.Signal a4    -- ^ input signal
>          -> SY.Signal a5    -- ^ input signal
>          -> ( SY.Signal b1
>             , SY.Signal b2
>             , SY.Signal b3) -- ^ 3 output signals
> comb53SY f s1 s2 s3 s4 s5
>   = (f -.- s1 -*- s2 -*- s3 -*- s4 -*- s5 -*<<)

To test the output, let us create five signals and a function that needs to be lifted. For the example, the terminal printouts should suffice to test our simple pattern.

< λ> import AtomExamples.GettingStarted.CustomPattern as CP
< λ> let fun a b c d e = (a+c+e, d-b, a*e)
< λ> let sy1 = SY.signal [1,2,3,4,5]
< λ> let sy2 = SY.comb11 (+10) sy1
< λ> let sy3 = SY.constant1 100
< λ> let de1 = DE.signal [(0,1),(3,2),(7,3),(9,4),(11,5)]
< λ> let de2 = DE.signal [(0,11),(3,12),(5,13),(9,14),(11,15)]
< λ> let de4 = DE.constant1 100
< λ> 
< λ> let (o1,o2,o3) = CP.comb53 fun sy1 sy1 sy2 sy2 sy3
< λ> o1
< λ> {112,114,116,118,120}
< λ> o2
< λ> {10,10,10,10,10}
< λ> o3
< λ> {100,200,300,400,500}
< λ> 
< λ> let (o1,o2,o3) = CP.comb53 fun de1 de1 de2 de2 de4
< λ> o1
< λ> { 112 @0s, 114 @3s, 115 @5s, 116 @7s, 118 @9s, 120 @11s}
< λ> o2
< λ> { 10 @0s, 10 @3s, 11 @5s, 10 @7s, 10 @9s, 10 @11s}
< λ> o3
< λ> { 100 @0s, 200 @3s, 200 @5s, 300 @7s, 400 @9s, 500 @11s}
< λ> 
< λ> let (o1,o2,o3) = CP.comb53SY fun sy1 sy1 sy2 sy2 sy3
< λ> o1
< λ> {112,114,116,118,120}
< λ> o2
< λ> {10,10,10,10,10}
< λ> o3
< λ> {100,200,300,400,500}
< λ> 
< λ> let (o1,o2,o3) = CP.comb53SY fun de1 de1 de2 de2 de4
< <interactive>:71:56-58:
<     Couldn't match type 'DE Integer' with 'SY b3'
<     Expected type: SY.Signal b3
<       Actual type: DE.Signal Integer
<     Relevant bindings include
<       it :: (SY.Signal b3, SY.Signal b2, SY.Signal b3)
<         (bound at <interactive>:71:1)
<     In the second argument of 'c0omb53SY', namely 'de1'
<     In the expression: comb53SY fun de1 de1 de2 de2 de4
< 
< ...

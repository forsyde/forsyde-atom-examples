The SY instance of the \texttt{toy} system is created using process constructor helpers defined in \href{\mocsyurl}{\texttt{ForSyDe.Atom.MoC.SY}}, and is defined in the following module (re-exported by \texttt{AtomExamples.GettingStarted}).

> module AtomExamples.GettingStarted.SY where

As in the previous examples we import the modules we need, and use aliases for referencing them in the code.

> import ForSyDe.Atom
> import ForSyDe.Atom.ExB.Absent (AbstExt)
> import ForSyDe.Atom.ExB             as ExB 
> import ForSyDe.Atom.MoC.SY          as SY
> import ForSyDe.Atom.Skeleton.Vector as V

Although Haskell's type engine can infer these type signatures, for the sake of documenting the interfaces for each stage, we will explicitly write their types. First, \texttt{stage1} is defined as a \href{\skelvecurl}{\texttt{farm}} network of \href{\mocsyurl}{\texttt{moore}} processes, where the initial states are provided by a vector. Its definition makes use of partial application (i.e. arguments which are not explicitly written are supposed to be the same on the LHS as on the RHS). It is defined hierarchically, making use of local name bindings after the \texttt{where} keyword.

> stage1SY :: V.Vector (AbstExt Int)             -- ^ vector of initial states
>          -> V.Vector (SY.Signal (AbstExt Int)) -- ^ vector of input signals
>          -> V.Vector (SY.Signal (AbstExt Int)) -- ^ vector of output signals
> stage1SY = V.farm21 pcSY
>   where
>     pcSY = SY.moore11 ns od
>     ns   = ExB.res21 (+)
>     od   = ExB.res11 id

Let us print and plot the inputs against the outputs, using the test signals and plotting functions \texttt{latexV} and \texttt{plotV} defined in \cref{sec:test-signals}:

< λ> isy
< <-1,1,-1,1>
< λ> vsy 
< <{1,1,1,1,1,1},{-1,1,-1,1,-1,1},{0,0,1,1,0},{-1,-1,-1,-1,-1}>
< λ> stage1SY isy vsy
< <{-1,0,1,2,3,4,5},{1,0,1,0,1,0,1},{-1,-1,-1,0,1,1},{1,0,-1,-2,-3,-4}>
< λ> let latexIn = latexV 6 ["sy1","sy2","sy3","sy4"] vsy
< λ> let latexS1 = latexV 7 ["sy1-1","sy2-1","sy3-1","sy4-1"] $ stage1SY isy vsy
< λ> let gnuIn = plotV 6 ["sy1","sy2","sy3","sy4"] vsy
< λ> let gnuS1 = plotV 7 ["sy1-1","sy2-1","sy3-1","sy4-1"] $ stage1SY isy vsy

\begin{figure}[ht!]
  \centering
  \subfloat[\texttt{latexIn}]{
    \includegraphics[width=.35\textwidth]{figs/sy-latex-in}
    \label{fig:sy-latex-in}}
  \hfill
  \subfloat[\texttt{latexS1}]{
    \includegraphics[width=0.4\textwidth]{figs/sy-latex-s1}
    \label{fig:sy-latex-s1}}%
  \hfill
  \subfloat[\texttt{gnuIn}]{
    \includegraphics[width=0.48\textwidth]{figs/sy-gnu-in}
    \label{fig:sy-gnu-in}}%
  \hfill
  \subfloat[\texttt{gnuS1}]{
    \includegraphics[width=0.48\textwidth]{figs/sy-gnu-s1}
    \label{fig:sy-gnu-s1}}%
\end{figure}

The second stage of the \texttt{toy} system in \cref{fig:subfig1} is defined as a \href{\skelvecurl}{\texttt{reduce}} network of \href{\mocsyurl}{\texttt{comb}} processes. As seen in its type signature, it inputs a vector of signals and it reduces it to a single signal. 

> stage2SY :: V.Vector (SY.Signal (AbstExt Int))
>          -> SY.Signal (AbstExt Int)
> stage2SY = V.reduce rSY
>   where
>     rSY = SY.comb21 (ExB.res21 (+))

Again, let us print and plot the output signals using the test inputs and utilities defined in \cref{sec:test-signals}.
  
< λ> let s2out = (stage2SY . stage1SY isy) vsy
< λ> s2out
< {0,-1,0,0,2,1}
< λ> let latexS2 = latex 7 ["sy1-2","sy2-2","sy3-2","sy4-2"] s2out
< λ> let gnuS2 = plot 7 ["sy1-2","sy2-2","sy3-2","sy4-2"] s2out


\begin{figure}[ht!]
  \centering
  \subfloat[\texttt{latexS2}]{
    \includegraphics[width=.45\textwidth]{figs/sy-latex-s2}
    \label{fig:sy-latex-s2}}
  \hfill
  \subfloat[\texttt{gnuS2}]{
    \includegraphics[width=.44\textwidth]{figs/sy-gnu-s2}
    \label{fig:sy-gnu-s2}}%
\end{figure}

Finally, the last stage of the \texttt{toy} system applies a \href{\mocsyurl}{\texttt{filter}} pattern on the reduced signal to mark all values less than 0 as absent.

> stage3SY :: SY.Signal (AbstExt Int)
>          -> SY.Signal (AbstExt Int)
> stage3SY = SY.filter (>=0)
>
> toySY :: V.Vector (AbstExt Int)             -- ^ initial states
>       -> V.Vector (SY.Signal (AbstExt Int)) -- ^ input
>       -> SY.Signal (AbstExt Int)            -- ^ output
> toySY i = stage3SY . stage2SY . stage1SY i

We print and plot the system response to the test signals defined in \cref{sec:test-signals}.

< λ> toySY isy vsy
< {0,⟂,0,0,2,1}
< λ> let latexS3 = latex 6 ["sy1-3"] $ toySY isy vsy
< λ> let gnuS3   = plot  6 ["sy1-3"] $ toySY isy vsy

\begin{figure}[ht!]
  \centering
  \subfloat[\texttt{latexS3}]{
    \includegraphics[width=.45\textwidth]{figs/sy-latex-s3}
    \label{fig:sy-latex-s3}}
  \hfill
  \subfloat[\texttt{gnuS3}]{
    \includegraphics[width=.44\textwidth]{figs/sy-gnu-s3}
    \label{fig:sy-gnu-s3}}%
\end{figure}

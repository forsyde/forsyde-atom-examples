\subsection{SDF instance}
\label{sec:getting-started:sdf-instance}

The SDF instance of the \texttt{toy} system is created using process constructor helpers defined in \href{\mocsdfurl}{\texttt{ForSdfDe.Atom.MoC.SDF}}, and can be found in the following module (re-exported by \texttt{AtomExamples.GettingStarted}).

> module AtomExamples.GettingStarted.SDF where

> import ForSyDe.Atom
> import ForSyDe.Atom.ExB.Absent (AbstExt)
> import ForSyDe.Atom.ExB             as ExB 
> import ForSyDe.Atom.MoC.SDF         as SDF
> import ForSyDe.Atom.Skeleton.Vector as V

\texttt{stage1} is defined as a \href{\skelvecurl}{\texttt{farm}} network of SDF \href{\mocsdfurl}{\texttt{moore}} processes. As SDF Moore processes are in principle graph loops, we take the initial tokens for each loop from a vector of lists of tokens. Also, both next state and output decoder functions are defined over lists of values instead of values, and they need to be provided within a context which describes the \emph{production} and \emph{consumption} rates. Read more about the particularities of SDF in the \href{\mocsdfurl}{API documentation}.

> stage1SDF :: V.Vector ([AbstExt Int])           -- ^ vector of initial tokens
>          -> V.Vector (SDF.Signal (AbstExt Int)) -- ^ vector of input signals
>          -> V.Vector (SDF.Signal (AbstExt Int)) -- ^ vector of output signals
> stage1SDF = V.farm21 pcSDF
>   where
>     pcSDF = SDF.moore11 ((1,2),1,ns) (1,1,od)
>     ns [x1] [y1,y2] = [ExB.res31 (\a b c -> a + b + c) x1 y1 y2]
>     od [x1]         = [ExB.res11 id x1]

Let us print and plot the inputs against the outputs, using the test signals and plotting functions \texttt{latexV} and \texttt{plotV} defined in \cref{sec:getting-started:test-signals}:

< λ> isdf
< <[-1],[1],[-1],[1]>
< λ> vsdf
< <{1,1,1,1,1,1},{-1,1,-1,1,-1,1},{0,0,1,1,0},{-1,-1,-1,-1,-1}>
< λ> stage1SDF isdf vsdf
< <{-1,1,3,5},{1,1,1,1},{-1,-1,1},{1,-1,-3}>
< λ> let latexIn = latexV 6 ["sdf1","sdf2","sdf3","sdf4"] vsdf
< λ> let latexS1 = latexV 7 ["sdf1-1","sdf2-1","sdf3-1","sdf4-1"] $ stage1SDF isdf vsdf
< λ> let gnuIn = plotV 6 ["sdf1","sdf2","sdf3","sdf4"] vsdf
< λ> let gnuS1 = plotV 7 ["sdf1-1","sdf2-1","sdf3-1","sdf4-1"] $ stage1SDF isdf vsdf

\begin{figure}[ht!]
  \centering
  \subfloat[\texttt{latexIn}]{
    \includegraphics[width=.35\textwidth]{sdf-latex-in}
    \label{fig:sdf-latex-in}}
  \hfill
  \subfloat[\texttt{latexS1}]{
    \includegraphics[width=0.25\textwidth]{sdf-latex-s1}
    \label{fig:sdf-latex-s1}}%
  \hfill
  \subfloat[\texttt{gnuIn}]{
    \includegraphics[width=0.4\textwidth]{sdf-gnu-in}
    \label{fig:sdf-gnu-in}}%
  \hfill
  \subfloat[\texttt{gnuS1}]{
    \includegraphics[width=0.4\textwidth]{sdf-gnu-s1}
    \label{fig:sdf-gnu-s1}}%
\end{figure}

\texttt{stage2} is again a \href{\skelvecurl}{\texttt{reduce}} network of \href{\mocsdfurl}{\texttt{comb}} processes. As with \texttt{stage1}, we need to provide the production and consumption rates.

> stage2SDF :: V.Vector (SDF.Signal (AbstExt Int))
>          -> SDF.Signal (AbstExt Int)
> stage2SDF = V.reduce rSDF
>   where
>     rSDF = SDF.comb21 ((1,1),1,rF)
>     rF [x1] [y1] = [ExB.res21 (+) x1 y1]

Again, let us print and plot the output signals using the test inputs and utilities defined in \cref{sec:getting-started:test-signals}.
  
< λ> let s2out = (stage2SDF . stage1SDF isdf) vsdf
< λ> s2out
< {0,0,2}
< λ> let latexS2 = latex 3 ["sdf1-2"] s2out
< λ> let gnuS2 = plot 3 ["sdf1-2"] s2out


\begin{figure}[ht!]
  \centering
  \subfloat[\texttt{latexS2}]{
    \includegraphics[width=.2\textwidth]{sdf-latex-s2}
    \label{fig:sdf-latex-s2}}
  \hfill
  \subfloat[\texttt{gnuS2}]{
    \includegraphics[width=.3\textwidth]{sdf-gnu-s2}
    \label{fig:sdf-gnu-s2}}%
\end{figure}

As for DE and CT instances, a SDF \texttt{filter} process does not really make sense in practice, but for the scope of this toy system, we need to instantiate one ourselves.

> stage3SDF :: SDF.Signal (AbstExt Int)
>          -> SDF.Signal (AbstExt Int)
> stage3SDF = sdfFilter (>=0)
>   where
>     sdfFilter p s   = SDF.comb21 ((2,2),2,filterF) (predSig p s) s
>     filterF pl sl   = zipWith ExB.filter pl sl
>     predSig   p s   = SDF.comb11 (1,1,fmap (ExB.res11 p)) s

>
> toySDF :: V.Vector ([AbstExt Int])           -- ^ initial tokens
>       -> V.Vector (SDF.Signal (AbstExt Int)) -- ^ input
>       -> SDF.Signal (AbstExt Int)            -- ^ output
> toySDF i = stage3SDF . stage2SDF . stage1SDF i

< λ> toySDF isdf vsdf
< {0,0}
< λ> let latexS3 = latex 3 ["sdf1-3"] $ toySDF isdf vsdf
< λ> let gnuS3   = plot  3 ["sdf1-3"] $ toySDF isdf vsdf

\begin{figure}[ht!]
  \centering
  \subfloat[\texttt{latexS3}]{
    \includegraphics[width=.2\textwidth]{sdf-latex-s3}
    \label{fig:sdf-latex-s3}}
  \hfill
  \subfloat[\texttt{gnuS3}]{
    \includegraphics[width=.3\textwidth]{sdf-gnu-s3}
    \label{fig:sdf-gnu-s3}}%
\end{figure}

\subsection{CT instance}
\label{sec:getting-started:ct-instance}

The CT instance of the \texttt{toy} looks exactly the same as the previous ones in \cref{sec:getting-started:sy-instance,sec:de-instance}, but is created using constructors from the \href{\moccturl}{\texttt{ForSyCt.Atom.MoC.CT}} module. The following file, as you are used to by now, is re-exported by \texttt{AtomExamples.GettingStarted}.

> module AtomExamples.GettingStarted.CT where

As prevoiusly, we use aliases for the imported modules.

> import ForSyDe.Atom
> import ForSyDe.Atom.ExB.Absent (AbstExt)
> import ForSyDe.Atom.ExB             as ExB 
> import ForSyDe.Atom.MoC.CT          as CT
> import ForSyDe.Atom.Skeleton.Vector as V

Again, \texttt{stage1} is a \href{\skelvecurl}{\texttt{farm}} network of CT \href{\moccturl}{\texttt{moore}} processes.

> stage1CT :: V.Vector (TimeStamp, Time -> AbstExt Time)  -- ^ vector of initial states
>          -> V.Vector (CT.Signal (AbstExt Time))         -- ^ vector of input signals
>          -> V.Vector (CT.Signal (AbstExt Time))         -- ^ vector of output signals
> stage1CT = V.farm21 pcCT
>   where
>     pcCT = CT.moore11 ns od
>     ns   = ExB.res21 (+)
>     od   = ExB.res11 id

We cannot print \texttt{ict} nor \texttt{vct} any more, but we can plot them. Again, the generated plots might need to be tweaked.

< λ> let latexIn = latexV 3.5 ["ct1","ct2","ct3","ct4"] vct
< λ> let latexS1 = latexV 3.5 ["ct1-1","ct2-1","ct3-1","ct4-1"] $ stage1CT ict vct
< λ> let gnuIn = plotV 3.5 ["ct1","ct2","ct3","ct4"] vct
< λ> let gnuS1 = plotV 3.5 ["ct1-1","ct2-1","ct3-1","ct4-1"] $ stage1CT ict vct

\begin{figure}[ht!]
  \centering
  \subfloat[\texttt{latexIn}]{
    \includegraphics[width=.43\textwidth]{ct-latex-in}
    \label{fig:ct-latex-in}}
  \hfill
  \subfloat[\texttt{latexS1}]{
    \includegraphics[width=0.43\textwidth]{ct-latex-s1}
    \label{fig:ct-latex-s1}}%
  \hfill
  \subfloat[\texttt{gnuIn}]{
    \includegraphics[width=0.43\textwidth]{ct-gnu-in}
    \label{fig:ct-gnu-in}}%
  \hfill
  \subfloat[\texttt{gnuS1}]{
    \includegraphics[width=0.43\textwidth]{ct-gnu-s1}
    \label{fig:ct-gnu-s1}}%
\end{figure}

The second stage is a \href{\skelvecurl}{\texttt{reduce}} network of CT \href{\moccturl}{\texttt{comb}} processes.

> stage2CT :: V.Vector (CT.Signal (AbstExt Time))
>          -> CT.Signal (AbstExt Time)
> stage2CT = V.reduce rCT
>   where
>     rCT = CT.comb21 (ExB.res21 (+))

< λ> let s2out   = (stage2CT . stage1CT ict) vct
< λ> let latexS2 = latex 3.3 ["ct1-2","ct2-2","ct3-2","ct4-2"] s2out
< λ> let gnuS2   = plot 3.3 ["ct1-2","ct2-2","ct3-2","ct4-2"] s2out

\begin{figure}[ht!]
  \centering
  \subfloat[\texttt{latexS2}]{
    \includegraphics[width=.5\textwidth]{ct-latex-s2}
    \label{fig:ct-latex-s2}}
  \hfill
  \subfloat[\texttt{gnuS2}]{
    \includegraphics[width=.43\textwidth]{ct-gnu-s2}
    \label{fig:ct-gnu-s2}}%
\end{figure}

For the last stage of the \texttt{toy} system  there is no CT process constructor in \href{\moccturl}{\texttt{ForSyDe.Atom.MoC.CT}} so we need to create it ourselves.

> stage3CT :: CT.Signal (AbstExt Time)
>          -> CT.Signal (AbstExt Time)
> stage3CT = ctFilter (>=0)
>   where
>     ctFilter p s = CT.comb21 ExB.filter (predSig p s) s
>     predSig  p s = CT.comb11 (ExB.res11 p) s
> 
> toyCT :: V.Vector (TimeStamp, Time -> AbstExt Time)  -- ^ initial states
>       -> V.Vector (CT.Signal (AbstExt Time))         -- ^ input
>       -> CT.Signal (AbstExt Time)                    -- ^ output
> toyCT i = stage3CT . stage2CT . stage1CT i

< λ> let latexS3 = latex 3.3 ["ct1-3"] $ toyCT ict vct
< λ> let gnuS3   = plot  3.3 ["ct1-3"] $ toyCT ict vct

\begin{figure}[ht!]
  \centering
  \subfloat[\texttt{latexS3}]{
    \includegraphics[width=.45\textwidth]{ct-latex-s3}
    \label{fig:ct-latex-s3}}
  \hfill
  \subfloat[\texttt{gnuS3}]{
    \includegraphics[width=.43\textwidth]{ct-gnu-s3}
    \label{fig:ct-gnu-s3}}%
\end{figure}

\subsection{DE instance}
\label{sec:getting-started:de-instance}

The DE instance of the \texttt{toy} looks exactly the same as the SY instance in \cref{sec:getting-started:sy-instance}, but is created using constructors from the \href{\mocdeurl}{\texttt{ForSyDe.Atom.MoC.DE}} module. This is why we will skip most of the description, and jump straight to testing it. The following file, as you are used to by now, is re-exported by \texttt{AtomExamples.GettingStarted}.

> module AtomExamples.GettingStarted.DE where

As previously, we use aliases for the imported modules.

> import ForSyDe.Atom
> import ForSyDe.Atom.ExB.Absent (AbstExt)
> import ForSyDe.Atom.ExB             as ExB 
> import ForSyDe.Atom.MoC.DE          as DE
> import ForSyDe.Atom.Skeleton.Vector as V

Again, we make the type signatures explicit for documentation purpose. For \texttt{stage1} we use the same  \href{\skelvecurl}{\texttt{farm}} network but now using DE \href{\mocdeurl}{\texttt{moore}} processes.

> stage1DE :: V.Vector (TimeStamp, AbstExt Int)  -- ^ vector of initial states
>          -> V.Vector (DE.Signal (AbstExt Int)) -- ^ vector of input signals
>          -> V.Vector (DE.Signal (AbstExt Int)) -- ^ vector of output signals
> stage1DE = V.farm21 pcDE
>   where
>     pcDE = DE.moore11 ns od
>     ns   = ExB.res21 (+)
>     od   = ExB.res11 id

When printing \texttt{ide} and \texttt{vde} we can see the effects of rounding the input floating point numbers to the nearest discrete timestamp. We also have to take into account that the \href{\mocdeurl}{DE version} of the Moore machine produces infinite signals when we print them out. Notice that the generated graphs may need to be tweaked in order to show the information properly.

< λ> ide
< <(1s,-1),(1.399999999999s,1),(1s,-1),(1.399999999999s,1)>
< λ> vde 
< <{ 1 @0s},{ -1 @0s, 1 @0.699999999999s, -1 @1.399999999999s, 1 @2.1s, -1 @2.799999999999s, 1 @3.5s},{ 0 @0s, 1 @1.399999999999s, 0 @2.799999999999s},{ -1 @0s}>
< λ> fmap (takeS 6) $ stage1DE ide vde
<{ -1 @0s, 0 @1s, 1 @2s, 2 @3s, 3 @4s, 4 @5s},{ 1 @0s, 0 @1.399999999999s, 2 @2.099999999998s, -1 @2.799999999998s, 1 @3.499999999997s, 3 @3.499999999999s},{ -1 @0s, -1 @1s, -1 @2s, 0 @2.399999999999s, 0 @3s, 1 @3.399999999999s},{ 1 @0s, 0 @1.399999999999s, -1 @2.799999999998s, -2 @4.199999999997s, -3 @5.599999999996s, -4 @6.999999999995s}>
< λ> let latexIn = latexV 3.3 ["de1","de2","de3","de4"] vde
< λ> let latexS1 = latexV 3.3 ["de1-1","de2-1","de3-1","de4-1"] $ stage1DE ide vde
< λ> let gnuIn = plotV 3.3 ["de1","de2","de3","de4"] vde
< λ> let gnuS1 = plotV 3.3 ["de1-1","de2-1","de3-1","de4-1"] $ stage1DE ide vde

\begin{figure}[ht!]
  \centering
  \subfloat[\texttt{latexIn}]{
    \includegraphics[width=.43\textwidth]{de-latex-in}
    \label{fig:de-latex-in}}
  \hfill
  \subfloat[\texttt{latexS1}]{
    \includegraphics[width=0.43\textwidth]{de-latex-s1}
    \label{fig:de-latex-s1}}%
  \hfill
  \subfloat[\texttt{gnuIn}]{
    \includegraphics[width=0.43\textwidth]{de-gnu-in}
    \label{fig:de-gnu-in}}%
  \hfill
  \subfloat[\texttt{gnuS1}]{
    \includegraphics[width=0.43\textwidth]{de-gnu-s1}
    \label{fig:de-gnu-s1}}%
\end{figure}

The second stage according to \cref{fig:subfig1} is also defined as a \href{\skelvecurl}{\texttt{reduce}} network but this time we use the DE process constructor for the \href{\mocdeurl}{\texttt{comb}} processes.

> stage2DE :: V.Vector (DE.Signal (AbstExt Int))
>          -> DE.Signal (AbstExt Int)
> stage2DE = V.reduce rDE
>   where
>     rDE = DE.comb21 (ExB.res21 (+))

< λ> let s2out = (stage2DE . stage1DE ide) vde
< λ> takeS 10 s2out
< { 0 @0s, 1 @1s, -1 @1.399999999999s, 0 @2s, 2 @2.099999999998s, 3 @2.399999999999s, -1 @2.799999999998s, 0 @3s, 1 @3.399999999999s, 3 @3.499999999997s}
< λ> let latexS2 = latex 3.3 ["de1-2","de2-2","de3-2","de4-2"] s2out
< λ> let gnuS2 = plot 3.3 ["de1-2","de2-2","de3-2","de4-2"] s2out

\begin{figure}[ht!]
  \centering
  \subfloat[\texttt{latexS2}]{
    \includegraphics[width=.5\textwidth]{de-latex-s2}
    \label{fig:de-latex-s2}}
  \hfill
  \subfloat[\texttt{gnuS2}]{
    \includegraphics[width=.43\textwidth]{de-gnu-s2}
    \label{fig:de-gnu-s2}}%
\end{figure}

For the last stage of the \texttt{toy} system  there is no DE process constructor in \href{\mocdeurl}{\texttt{ForSyDe.Atom.MoC.DE}} so we need to create it ourselves.

> stage3DE :: DE.Signal (AbstExt Int)
>          -> DE.Signal (AbstExt Int)
> stage3DE = deFilter (>=0)
>   where
>     deFilter p s = DE.comb21 ExB.filter (predSig p s) s
>     predSig  p s = DE.comb11 (ExB.res11 p) s
> 
> toyDE :: V.Vector (TimeStamp, AbstExt Int)  -- ^ initial states
>       -> V.Vector (DE.Signal (AbstExt Int)) -- ^ input
>       -> DE.Signal (AbstExt Int)            -- ^ output
> toyDE i = stage3DE . stage2DE . stage1DE i

< λ> takeS 10 $ toyDE ide vde
< { 0 @0s, 1 @1s, ⟂ @1.399999999999s, 0 @2s, 2 @2.099999999998s, 3 @2.399999999999s, ⟂ @2.799999999998s, 0 @3s, 1 @3.399999999999s, 3 @3.499999999997s}
< λ> let latexS3 = latex 3.3 ["de1-3"] $ toyDE ide vde
< λ> let gnuS3   = plot  3.3 ["de1-3"] $ toyDE ide vde

\begin{figure}[ht!]
  \centering
  \subfloat[\texttt{latexS3}]{
    \includegraphics[width=.45\textwidth]{de-latex-s3}
    \label{fig:de-latex-s3}}
  \hfill
  \subfloat[\texttt{gnuS3}]{
    \includegraphics[width=.43\textwidth]{de-gnu-s3}
    \label{fig:de-gnu-s3}}%
\end{figure}

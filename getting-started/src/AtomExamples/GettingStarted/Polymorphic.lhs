\subsection{Polymorphic instance}
\label{sec:getting-started:poly-instance}

In the previous section you've seen how to model systems in \textsc{ForSyDe-Atom} using the helper functions for instantiating process constructors in different MoCs. In this section we will be instantiating the "raw" polymorphic form of the same process constructors, not overloaded with any execution semantics. The execution semantics are deduced from the tag system of the input signals, i.e. their types. These process constructors are defined as patterns of MoC atoms in the \href{\mocurl}{\texttt{ForSdfDe.Atom.MoC}} module. The code below is exported by \texttt{AtomExamples.GettingStarted}.

> module AtomExamples.GettingStarted.Polymorphic where

Notice that apart from the polymorphic MoC patterns, we are also using "raw" extended behavior and skeleton patterns.

> import ForSyDe.Atom
> import ForSyDe.Atom.MoC.SDF (Prod, Cons)
> import ForSyDe.Atom.ExB      as ExB 
> import ForSyDe.Atom.MoC      as MoC
> import ForSyDe.Atom.Skeleton as Skel

\texttt{stage1} is defined, like in all previous instances, as a \href{\skelurl}{\texttt{farm}} network of \href{\mocurl}{\texttt{moore}} processes. 

> stage1 :: (Skeleton s, MoC m, ExB b)
>        => Fun m (b a) (Fun m (b a) (Ret m (b a))) -- ^ next state function
>        -> Fun m (b a) (Ret m (b a)) -- ^ output decoder function
>        -> s (Stream (m (b a))) -- ^ signals with initial tokens
>        -> s (Stream (m (b a))) -- ^ vector of input signals
>        -> s (Stream (m (b a))) -- ^ vector of output signals
> stage1 ns od = Skel.farm21 (MoC.moore11 ns od)

We can immediately observe some main differences in the type signature. First, the \texttt{Vector}, \texttt{Signal} and \texttt{AbstExt} data types are not explicit any more, but suggested as type constraints. The first line in the type signature \texttt{(Skel s, MoC m, ExB b)} suggests that the type of \texttt{s} should belong to the skeleton layer, the type of \texttt{m} should belong to the MoC layer and the type of \texttt{b} should belong to the extended behavior layer. Another peculiarity is the presence of the first two structures, but there should be nothing frightening about them: e.g. a structure \texttt{Fun m a (Fun m b (Ret m c))} simply stands for the type of a function \texttt{a -> b -> c}, which was wrapped in a context specific to a MoC \texttt{m}. Read the MoC layer's \href{\mocurl}{API documentation} for more on function contexts. This means that the functions for the next state decoder and the output decoder need to be provided as arguments for \texttt{stage1}, and they might differ depending on the MoCs. A third peculiarity is that the initial states are provided as signals and not through some specific structure any more. Indeed, the \href{\mocurl}{MoC atoms} extract initial states from signals, and deal with them in different ways depending on the MoC they implement.

The main two classes of MoCs, based on their notion of tags, but also based on how they deal with events, are \emph{timed} MoCs (e.g. SY, DE, CT) and \emph{untimed} MoCs (e.g. SDF). Concerning the functions they lift from layers below, we can say that in \textsc{ForSyDe-Atom} timed MoCs lift functions on individual values, whereas untimed MoCs lift functions on lists of values (i.e. multiple tokens). Based on this observation, let us define the next state and output decoders for timed and untimed/SDF MoCs.

> nsT :: (ExB b, Num a) => b a -> b a -> b a
> odT :: (ExB b, Num a) => b a -> b a
> nsT  = ExB.res21 (+)
> odT  = ExB.res11 id
> 
> nsSDF :: (ExB b, Num a) => (Cons, [b a] -> (Cons, [b a] -> (Prod, [b a])))
> odSDF :: (ExB b, Num a) => (Cons, [b a] -> (Prod, [b a]))
> nsSDF = MoC.ctxt21 (1,2) 1 (\[x1] [y1,y2] -> [ExB.res31 (\a b c -> a + b + c) x1 y1 y2])
> odSDF = MoC.ctxt11 1     1 (\[x1]         -> [ExB.res11 id x1])

\textbf{OBS:} for the sake of simplicity, the ExB component has been left as part of the \texttt{nsT} and \texttt{odT}, respectively \texttt{nsSDF} and \texttt{odSDF}, and not part of \texttt{stage1}. Describing all layers within the \texttt{stage1} function would have rendered the type signature a bit more complicated and is left as an exercise for the reader.

We postpone plotting the input and output signals for later. Carrying on with instatiating \texttt{stage2} as a \href{\skelurl}{\texttt{reduce}} network of \href{\mocurl}{\texttt{comb}} processes:

> stage2 :: (Skeleton s, MoC m, ExB b)
>        => Fun m (b a) (Fun m (b a) (Ret m (b a))) -- ^ reduce function
>        -> s (Stream (m (b a)))                    -- ^ vector of input signals
>        -> Stream (m (b a))                        -- ^ output signal
> stage2 r = Skel.reduce (MoC.comb21 r)

Again, the passed functions need to be specifically defined for each MoC, and for simplicity we include the ExB part as well:

> rT :: (ExB b, Num a) => b a -> b a -> b a
> rT  = ExB.res21 (+)
> 
> rSDF :: (ExB b, Num a) => (Cons, [b a] -> (Cons, [b a] -> (Prod, [b a])))
> rSDF = MoC.ctxt21 (1,1) 1 (\[x1] [y1] -> [ExB.res21 (+) x1 y1])

Finally \texttt{stage3}, the \texttt{filter} pattern, we create it ourselves in terms of existing ones. This time we incorporate the extended behaviors in the definition of \texttt{stage3}, an we only ask for a context wrapper as input argument. Don't be alarmed by the scary type signature, the actual implementation is quite elegant.

> stage3 :: (MoC m, ExB b, Ord a, Num a)
>        => ((b a -> b a)
>            -> Fun m (b a) (Ret m (b a))) -- ^ context wrapper for the filter behavior
>        -> Stream (m (b a))               -- ^ input signal
>        -> Stream (m (b a))               -- ^ output signal
> stage3 fctx = MoC.comb11 (fctx filtF) 
>   where filtF a = ExB.filter (ExB.res11 (>=0) a) a

And now for the timed/untimed context wrappers:

> fctxT     = id
> fctxSDF f = MoC.ctxt11 2 2 (fmap f)

The full definition of the \texttt{toy} system:

> toy ns od r fctx is = stage3 fctx . stage2 r . stage1 ns od is

And that's it! Let us plot now the test signals and the responses of the system for each stage. This time we will use only \LaTeX\ plots. We can also plot initial states as they are wrapped as signals. The test results can be seen in \cref{fig:poly-test}.

< λ> let noLabel = ["","","",""]
< λ> let iSDF = latexV 2 noLabel sisdf
< λ> let iSY  = latexV 2 noLabel sisy
< λ> let iDE  = latexV 2 noLabel side
< λ> let iCT  = latexV 2 noLabel sict
< λ>
< λ> let vSDF = latexV 6   noLabel vsdf
< λ> let vSY  = latexV 6   noLabel vsy
< λ> let vDE  = latexV 3.3 noLabel vde
< λ> let vCT  = latexV 3.3 noLabel vct
< λ>
< λ> let s1SDF = latexV 6   noLabel $ stage1 nsSDF odSDF sisdf vsdf
< λ> let s1SY  = latexV 6   noLabel $ stage1 nsT   odT   sisy  vsy
< λ> let s1DE  = latexV 3.3 noLabel $ stage1 nsT   odT   side  vde
< λ> let s1CT  = latexV 3.3 noLabel $ stage1 nsT   odT   sict  vct
< λ>
< λ> let s2 ns od r is = stage2 r . stage1 ns od is
< λ> let s2SDF = latex 6   noLabel $ s2 nsSDF odSDF rSDF sisdf vsdf
< λ> let s2SY  = latex 6   noLabel $ s2 nsT   odT   rT   sisy  vsy
< λ> let s2DE  = latex 3.3 noLabel $ s2 nsT   odT   rT   side  vde
< λ> let s2CT  = latex 3.3 noLabel $ s2 nsT   odT   rT   sict  vct
< λ>
< λ> let s3SDF = latex 6   noLabel $ toy nsSDF odSDF rSDF fctxSDF sisdf vsdf
< λ> let s3SY  = latex 6   noLabel $ toy nsT   odT   rT   fctxT   sisy  vsy
< λ> let s3DE  = latex 3.3 noLabel $ toy nsT   odT   rT   fctxT   side  vde
< λ> let s3CT  = latex 3.3 noLabel $ toy nsT   odT   rT   fctxT   sict  vct


\begin{sidewaysfigure}[p]\centering
\begin{tabular}{ c c c c c }
  \subfloat[\texttt{iSDF}]{
    \includegraphics[scale=.66]{p-sdf-latex-is}
    \label{fig:p-sdf-latex-is}}%
  &
  \subfloat[\texttt{vSDF}]{
    \includegraphics[scale=.66]{p-sdf-latex-iv}
    \label{fig:p-sdf-latex-iv}}%
  &
  \subfloat[\texttt{s1SDF}]{
    \includegraphics[scale=.66]{p-sdf-latex-s1}
    \label{fig:p-sdf-latex-s1}}%
  &
  \subfloat[\texttt{s2SDF}]{
    \includegraphics[scale=.66]{p-sdf-latex-s2}
    \label{fig:p-sdf-latex-s2}}%
  &
  \subfloat[\texttt{s3SDF}]{
    \includegraphics[scale=.66]{p-sdf-latex-s3}
    \label{fig:p-sdf-latex-s3}}%
  \\
  \subfloat[\texttt{iSY}]{
    \includegraphics[scale=.66]{p-sy-latex-is}
    \label{fig:p-sy-latex-is}}%
  &
  \subfloat[\texttt{vSY}]{
    \includegraphics[scale=.66]{p-sy-latex-iv}
    \label{fig:p-sy-latex-iv}}%
  &
  \subfloat[\texttt{s1SY}]{
    \includegraphics[scale=.66]{p-sy-latex-s1}
    \label{fig:p-sy-latex-s1}}%
  &
  \subfloat[\texttt{s2SY}]{
    \includegraphics[scale=.66]{p-sy-latex-s2}
    \label{fig:p-sy-latex-s2}}%
  &
  \subfloat[\texttt{s3SY}]{
    \includegraphics[scale=.66]{p-sy-latex-s3}
    \label{fig:p-sy-latex-s3}}%
  \\
  \subfloat[\texttt{iDE}]{
    \includegraphics[scale=.66]{p-de-latex-is}
    \label{fig:p-de-latex-is}}%
  &
  \subfloat[\texttt{vDE}]{
    \includegraphics[scale=.66]{p-de-latex-iv}
    \label{fig:p-de-latex-iv}}%
  &
  \subfloat[\texttt{s1DE}]{
    \includegraphics[scale=.66]{p-de-latex-s1}
    \label{fig:p-de-latex-s1}}%
  &
  \subfloat[\texttt{s2DE}]{
    \includegraphics[scale=.66]{p-de-latex-s2}
    \label{fig:p-de-latex-s2}}%
  &
  \subfloat[\texttt{s3DE}]{
    \includegraphics[scale=.66]{p-de-latex-s3}
    \label{fig:p-de-latex-s3}}%
  \\
  \subfloat[\texttt{iCT}]{
    \includegraphics[scale=1.2]{p-ct-latex-is}
    \label{fig:p-ct-latex-is}}%
  &
  \subfloat[\texttt{vCT}]{
    \includegraphics[scale=1.2]{p-ct-latex-iv}
    \label{fig:p-ct-latex-iv}}%
  &
  \subfloat[\texttt{s1CT}]{
    \includegraphics[scale=1.2]{p-ct-latex-s1}
    \label{fig:p-ct-latex-s1}}%
  &
  \subfloat[\texttt{s2CT}]{
    \includegraphics[scale=1.2]{p-ct-latex-s2}
    \label{fig:p-ct-latex-s2}}%
  &
  \subfloat[\texttt{s3CT}]{
    \includegraphics[scale=1.2]{p-ct-latex-s3}
    \label{fig:p-ct-latex-s3}}%
\end{tabular}
\caption[Test input and output signals for a polymorphic process network]{Inputs and outputs for the polymorphic \texttt{toy} system in \cref{sec:getting-started:poly-instance}}
\label{fig:poly-test}
\end{sidewaysfigure}

As expected, the results in \cref{fig:poly-test} are exactly the same as the ones presented in \cref{sec:getting-started:sy-instance,sec:de-instance,sec:ct-instance,sec:sdf-instance}. In conclusion we have succesfully instantiated a MoC-agnostic system, whose execution semantics are inferred according to the input data types. This is possible thanks to the notion of type classes, inferred from the host language Haskell. In this section, instead of MoC-specific helpers, we have used the "raw" process constructors as defined in the \href{\mocurl}{\texttt{ForSdfDe.Atom.MoC}} module as patterns of MoC-layer atoms.

This example, used as a case study by \cite{Ungureanu17}, has been focused on the MoC layer. A similar approach based on atom polymorphism could target other layers as well since, as you have seen, all layers are implemented as type classes. At the moment of writing this report the extended behavior layer was represented only by the \texttt{AbstExt} type, while the skeleton layer had only \texttt{Vector}. Nevertheless, future iterations of \textsc{ForSyDe-Atom} will describe more types. 

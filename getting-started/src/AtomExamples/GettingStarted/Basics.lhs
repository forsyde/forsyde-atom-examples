This section introduces some basic modeling features of \textsc{ForSyDe-Atom}, such as helpers and process constructors. The module is re-exported by \texttt{AtomExamples.GettingStarted} which is pre-loaded in a \texttt{repl} session, so there is no need to import it manually.

> module AtomExamples.GettingStarted.Basics where

We usually start a \textsc{ForSyDe-Atom} module by importing the \texttt{ForSyDe.Atom} library which provides some commonly used types and utilities.

> import ForSyDe.Atom

In this section we will only test \href{\mocsyurl}{synchronous processes} as patterns defined in the \href{\mocurl}{MoC} layer. An extensive library of types, utilities and helpers for SY process constructors can be used by importing the \href{\mocsyurl}{\texttt{ForSyDe.Atom.MoC.SY}} module.

> import ForSyDe.Atom.MoC.SY

Next we import the \texttt{Absent} extended behavior, defined in the \href{\exburl}{ExB} layer, to get a glimpse of modeling using multiple layers. As with the previous, we need to specifically import the \href{\exbabsurl}{\texttt{ForSyDe.Atom.ExB.Absent}} library to access the helpers and types.

> import ForSyDe.Atom.ExB (res11, res21)
> import ForSyDe.Atom.ExB.Absent

The \href{\atomurl}{\emph{signal}} is the basic data type defined in the MoC layer, and it encodes a \emph{tag system} which describes time, causality and other key properties of CPS. In the case of SY MoC, a signal defines a total order between events. There are several ways to instantiate a signal in \textsc{ForSyDe-Atom}. The most usual one is to create it from a list of values using the \href{\mocsyurl}{\texttt{signal}} helper. By studying its type signature in the \href{\mocsyurl}{online API documentation}, one can see that it needs a list of elements of type \texttt{a} as argument, so let us create a test signal \texttt{testsig1}:

> testsig1 = signal [1,2,3,4,5]


You can print or check the type of \texttt{testsig1}

< *AtomExamples.GettingStarted> testsig1
< {1,2,3,4,5}
< *AtomExamples.GettingStarted> :t testsig1
< testsig1 :: ForSyDe.Atom.MoC.SY.Core.Signal Integer

The type of \texttt{testsig1} tells us that the \texttt{signal} helper created a SY \texttt{Signal} carrying \texttt{Integer} values. If you are curious, you can print some information about this mysterious type

< *AtomExamples.GettingStarted> :info ForSyDe.Atom.MoC.SY.Core.Signal
< type ForSyDe.Atom.MoC.SY.Core.Signal a =
<   Stream (ForSyDe.Atom.MoC.SY.Core.SY a)
<   	-- Defined in ForSyDe.Atom.MoC.SY.Core

which shows that it is in fact a type alias for a \href{\mocstreamurl}{\texttt{Stream}} of \href{\mocsyurl}{\texttt{SY}} events. If this became too confusing, please read the MoC layer overview in this \href{\atomurl}{online API documentation page}. Unfortunately the names printed as interactive information are verbose and show their exact location in the structure of \textsc{ForSyDe-Atom}. We do not care about this in the source code, since we imported the SY library properly. To benefit from the same treatment in the interpreter session, we need to do the same:


< *AtomExamples.GettingStarted> import ForSyDe.Atom.MoC.SY as SY
< *AtomExamples.GettingStarted SY> :info Signal 
< type Signal a = Stream (SY a)
<  	-- Defined in ForSyDe.Atom.MoC.SY.Core

Another way of creating a SY signal is by means of a \href{\mocsyurl}{\texttt{generate}} process, which generates an infinite signal from a kernel value. By studying the \href{\mocsyurl}{\texttt{online API documentation}}, you can see that the SY library provides a number of helpers for this particular process constructor, the one generating one output signal being \texttt{generate1}. Let us first check the type signature for this helper function:

< *AtomExamples.GettingStarted SY> :t generate1
< generate1 :: (b1 -> b1) -> b1 -> Signal b1

So basically, as suggested in the \href{\mocsyurl}{\texttt{online API documentation}}, this helper takes a "next state" function of type \texttt{a -> a}, a kernel value of type \texttt{a}, and it generates a signal of tyle \texttt{Signal a}. With this in mind, let us create \texttt{testsig2}: 

> testsig2 = generate1 (+1) 0

Printing it would jam the terminal... we were serious when we said "infinite"! This is why you need to select a few events from the beginning to see whether the signal generator behaves correctly. To do so, we use the \texttt{takeS} utility:

< *AtomExamples.GettingStarted SY> takeS 10 testsig2
< {0,1,2,3,4,5,6,7,8,9}
< *AtomExamples.GettingStarted SY> :t testsig2
< testsig2 :: Signal Integer

\texttt{generate} was a process with no inputs. Now let us try a process that takes the two signals \texttt{testsig1} and \texttt{testsig2} and sums their synchronous events. For this we use the combinatorial process \texttt{comb}, and the SY constructor we need, with two inputs and one output is provided by \href{\mocsyurl}{\texttt{comb21}}. Again, checking the type signature confirms that this is the helper we need:

< *AtomExamples.GettingStarted SY> :t comb21
< comb21 :: (a1 -> a2 -> b1) -> Signal a1 -> Signal a2 -> Signal b1

So let us instantiate \texttt{testproc1}:

> testproc1 = comb21 (+)

Calling it in the interpreter with \texttt{testsig1} and \texttt{testsig2} as arguments, it returns:

< *AtomExamples.GettingStarted SY> testproc1 testsig2 testsig1
< {1,3,5,7,9}

which is the expected output, as based on the definition of the SY MoC, all events following the sixth one from \texttt{testsig2} are not synchronous to any event in \texttt{testsig1}.

\begin{figure}[ht!]\centering
\includegraphics[]{figs/basics-pn.pdf}
\caption{Simple process network as composition of processes}
\label{fig:basic-composite}
\end{figure}

Suppose we want to increment every event of \texttt{testsig2} with 1 before summing the two signals. This particular behavior is described by the process network in \cref{fig:basic-composite}. There are multiple ways to instantiate this process network, mainly depending on the coding style of the user:

> testpn1       = comb21 (+) . comb11 (+1)
> testpn2 s2 s1 = testproc1 (comb11 (+1) s2) s1
> testpn3 s2    = testproc1 (comb11 (+1) s2)
> testpn4 s2 s1 = let s2' = comb11 (+1) s2
>                 in  testproc1 s2' s1
> testpn5 s2    = comb21 (+)  s2'
>   where s2'   = comb11 (+1) s2

All of the above functions are equivalent. \texttt{testpn1} uses the point-free notation, i.e. the function composition operator, between two partially-applied process constructors. \texttt{testpn2} makes use of the previously-defined \texttt{testproc1} to enforce a global hierarchy. \texttt{testpn3} is practically the same, but it exposes the partial application mechanism, by not making the \texttt{s1} argument explicit. \texttt{testpn4} makes use of local hierarchy in form of a let-binding, while \texttt{testpn5} does so through a where clause. Printing them only confirms their equivalence:

< *AtomExamples.GettingStarted SY> testpn1 testsig2 testsig1
< {2,4,6,8,10}
< *AtomExamples.GettingStarted SY> testpn2 testsig2 testsig1
< {2,4,6,8,10}
< *AtomExamples.GettingStarted SY> testpn3 testsig2 testsig1
< {2,4,6,8,10}
< *AtomExamples.GettingStarted SY> testpn4 testsig2 testsig1
< {2,4,6,8,10}
< *AtomExamples.GettingStarted SY> testpn5 testsig2 testsig1
< {2,4,6,8,10}

One key concept of \textsc{ForSyDe-Atom} is the ability to model different aspects of a system as orthogonal layers. Up until now we only experimented with two layers: the MoC layer, which concerns timing and synchronization issues, and the function layer, which concerns functional aspects, such as arithmetic and data computation. Let us rewind which DSL blocks we have used an group them by which layer they belong:

* the \texttt{Integer} values carried by the two test signals (i.e. \texttt{0, 1, ...}) and the arithmetic functions (i.e. \texttt{(+)} and \texttt{(+1)}) belong to the \emph{function layer}.
* the signal structures for \texttt{testsig1} and \texttt{testsig2} (i.e. \texttt{Signal a}) the utility (i.e. \texttt{signal}) and the process constructors (i.e. \texttt{generate1}, \texttt{comb11} and \texttt{comb21}) belong to the \emph{MoC layer}.

It is easy to grasp the concept of layers once you understand how \emph{higher order functions} work, and accept that \textsc{ForSyDe-Atom} basically relies on the power of functional programming to define structured abstractions. In the previous case entities from the MoC layer "wrap around" entities from the function layer like in \cref{fig:basic-2layer}, "lifting" them into the MoC domain. Unfortunately it is not that straightforward to see from the code syntax which entity belongs to which layer. For now, their membership can be determined solely by the user's knowledge of where each function is defined, i.e. in which module. Later in this guide we will make this apparent from the code syntax, but for now you will have to trust us.

\begin{figure}[ht!]\centering
\begin{minipage}{.45\textwidth}\centering
 \includegraphics[width=\linewidth]{figs/basics-2layer.pdf}
 \caption{Layered structure of the processes in fig.~\ref{fig:basic-composite}}
 \label{fig:basic-2layer}
\end{minipage}\hfill%
\begin{minipage}{.46\textwidth}\centering
 \includegraphics[width=\linewidth]{figs/basics-3layer.pdf}
 \caption{Layered structure of the processes describing absent events}
 \label{fig:basic-3layer}
\end{minipage}
\end{figure}

As a last exercise for this section we would like to extend the behavior of the system in \cref{fig:basic-composite} in order to describe whether the events are happening or not (i.e. are absent or present) and act accordingly. For this, \textsc{ForSyDe-Atom} defines the \emph{Extended Behavior (ExB) layer}. As suggested in \cref{fig:basic-3layer}, this layer extends the pool of values with symbols denoting states which would be impossible to describe using normal values, and associates some default behaviors (e.g. protocols) over these symbols.

The two processes \cref{fig:basic-composite} are now defined below as \texttt{testAp1} and \texttt{testAp2}. This time, apart from the functional definition (\texttt{name = function}) we specify the type signature as well (\texttt{name :: type}), which in the most general case can be considered a specification/contract of the interfaces of the newly instantiated component. Both type signatures and function definitions expose the layered structure suggested in \cref{fig:basic-3layer}. As specific ExB type, we use \href{\exbabsurl}{\texttt{AbstExt}} and as behavior pattern constructor we choose a default behavior expressing a resolution {\href{\exburl}{\texttt{res}}}.

> testAp1 :: Num a
>         => Signal (AbstExt a) -- ^ input signal of absent-extended values
>         -> Signal (AbstExt a) -- ^ output signal of absent-extended values
> testAp1 = comb11 (res11 (+1))

> testAp2 :: Num a
>         => Signal (AbstExt a) -- ^ first input signal of absent-extended values
>         -> Signal (AbstExt a) -- ^ second input signal of absent-extended values
>         -> Signal (AbstExt a) -- ^ output signal of absent-extended values
> testAp2 = comb21 (res21 (+))

Now all we need is to create some test signals of type \texttt{Signal (AbstExt a)}. One way is to use the \href{\mocsyurl}{\texttt{signal}} utility like for \texttt{testAsig1}, but this forces to make use of \texttt{AbstExt}'s type constructors. Another way is to use the library-provided process constructor helpers, such as \href{\mocsyurl}{\texttt{filter'}}, like for \texttt{testAsig2}.

> testAsig1 = signal [Prst 1, Prst 2, Abst, Prst 4, Abst]
> testAsig2 = filter' (/=4) testsig2

Printing out the test signals in the interpreter session this is what we get:

< *AtomExamples.GettingStarted SY> testAsig1
< {1,2,⟂,4,⟂}
< *AtomExamples.GettingStarted SY> takeS 10 testAsig2
< {0,1,2,3,⟂,5,6,7,8,9}

Trying out \texttt{testAp1} on \texttt{testAsig1}:

< *AtomExamples.GettingStarted SY> testAp1 testAsig1 
< {2,3,⟂,5,⟂}

Everything seems all right. Now testing \texttt{testAp2} on \texttt{testAsig1} and \texttt{testAsig2}:

< *AtomExamples.GettingStarted SY> takeS 10 $ testAp2 testAsig2 testAsig1
< {1,3,*** Exception: [ExB.Absent] Illegal occurrence of an absent and present event

Uh oh... Actually this \emph{is} the correct behavior of a resolution function for absent events, as defined in synchronous reactive languages such as Lustre \cite{halbwachs91}. Let us remedy the situation, but this time using another library-provided process constructor, \href{\mocsyurl}{\texttt{when'}}. 

> testAsig2' = when' mask testsig2
>   where
>     mask = signal [True, True, False, True, False]

Now printing \texttt{testAp2} looks better:

< *AtomExamples.GettingStarted SY> testAsig2'
< {0,1,⟂,3,⟂}
< *AtomExamples.GettingStarted SY> testAp2 testAsig2' testAsig1
< {1,3,⟂,7,⟂}

And recreating the process network from \cref{fig:basic-composite} gives the expected result:

> testApn1 = testAp2 . testAp1

< *AtomExamples.GettingStarted SY> testApn1 testAsig2' testAsig1
< {2,4,⟂,8,⟂}

This section has provided a crash course in modeling with \textsc{ForSyDe-Atom}, with focus on a few practical matters, such as using library-provided helpers and constructors and understanding the role of layers. The following sections delve deeper into modeling concepts such as atoms and making use of ad-hoc polymorphism.

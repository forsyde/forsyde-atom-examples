> {-# LANGUAGE PostfixOperators, TypeFamilies  #-}  

\section{An FFT network}
\label{sec:an-fft-network}

This example shows how to instantiate an FFT butterfly process network using skeleton layer constructors operating on \texttt{Vector} types, and simulates the system's response to signals of different MoCs.  It was inspired from \cite{reekie95}.

To be consistent with the current chapter, we shall separate the interconnection network expressed in terms of skeleton layer constructors, from the functional/behavioral/timing components further enforcing the practice of \emph{orthogonalization} of concerns in system design. Also, to demonstrate the elegance of this approach, we shall construct two different functionally-equivalent systems which expose different propoerties: a) the butterfly pattern as a network of interconnected processes communicating through (vectors of) signals; b) the FFT as a process operating on a signal (of vectors). Each of these two cases will be fed with signals of different MoCs to further demonstrate the independence of the atom (i.e. constructor) composition from the semantics carried by atoms themselves.

> module AtomExamples.Skeleton.FFT where

Following are the loaded modules. We import most modules qualified to explicitly show to which layer or class a certain constructor belongs to. While, from a system designer's perspective, loading the \texttt{Behavior} and \texttt{MoC} modules seems redundant since there exist equivalent helpers for each MoC for instantiating the desired processes, we do want to show the interaction between (and actually the separation of) each layer. 

> import           ForSyDe.Atom
> import qualified ForSyDe.Atom.MoC             as MoC
> import qualified ForSyDe.Atom.MoC.SY          as SY  
> import qualified ForSyDe.Atom.MoC.DE          as DE  
> import qualified ForSyDe.Atom.MoC.CT          as CT  
> import qualified ForSyDe.Atom.MoC.SDF         as SDF
> import qualified ForSyDe.Atom.Skeleton.Vector as V

The \texttt{Data.Complex} module is needed for the complex arithmetic computations performed by a ``butterfly'' element. It provides the \texttt{cis} function for conversion towards a complex number, and the \texttt{magnitude} function for extracting the magnitude of a complex number.

> import Data.Complex
>-- import Data.Ratio
>-- import System.Process

> type C = Complex Double
  
\subsection{The butterfly network}
\label{sec:butterfly-network}

The Fast Fourier Transform (FFT) is an algorithm for computing the Discrete Fourier Transform (DFT), formulated by Cooley-Tukey as a ``divide-and-conquer'' algorithm computing \eqref{eq:dft}, where $N$ is the number of signal samples, also called \emph{bins}.

\begin{equation}\label{eq:dft}
  X_k = \sum_{n=0}^{N-1}x_n e^{-i2\pi k n / N}\quad\text{ where }\quad k=0,...,N-1 
\end{equation}

This algorithm is often implemented in an iterative manner for reasons of efficiency. Figure \ref{fig:fft-struct} shows an example diagram for visualizing this algorithm, and we shall encode precisely this diagram as a network of interconnected processes (or functions).

We start by computing a vector of ``twiddle'' factors, which are complex numbers situated on the unit circle. For $n=16$, the value of this vector is:
\begin{equation}\label{eq:twiddles}
  \SkelVec{W_{16}^0,W_{16}^4,W_{16}^2,W_{16}^6,W_{16}^1,W_{16}^5,W_{16}^3,W_{16}^7}
\ quad\text{ where }\quad W_{N}^m = e^{-2\pi m / N}
\end{equation}
the actual vector is obtained by mapping the function \texttt{bW} over a vector of \texttt{indexes} and \texttt{bitrevers}ing the result.

\begin{equation}\label{eq:1}
  \begin{aligned}
  &\id{twiddles} : \mathbb{N} \rightarrow \SkelVec{\mathbb{C}}\\
  &\id{twiddles}\ N = (\SkelCons{reverse} \circ \SkelCons{bitrev} \circ \SkelCons{take}\ {N/2}) (\left(k \mapsto\frac{-2i\pi k}{N}\right)  \SkelFrm \SkelVec{0..})
\end{aligned}
\end{equation}

> twiddles :: Integer -> V.Vector C
> twiddles bN = V.reverse $ V.bitrev $ V.take (bN `div` 2) $ V.farm11 bW V.indexes
>   where bW k = (cis . negate) (-2 * pi * fromInteger (k - 1) / fromInteger bN)

% $

\begin{align}
  \SkelCons{fft}\ k\ vs =&\ \SkelCons{bitrev} ((\id{stage} \SkelFun \id{kern}) \SkelPip vs)
  \intertext{where the constructors}
  \id{stage}\ N     =&\ \SkelCons{concat} \circ (segment \SkelFun \id{twiddles}) 
                       \circ \SkelCons{group}\ N  \\  
  \id{segment}\ t   =&\ \SkelCons{unduals} \circ (\id{butterfly}\ t\ \SkelFrm)
                       \circ \SkelCons{duals}  \\
  \id{butterfly}\ w =&\ ((x_0\ x_1 \mapsto x_0 + wx_1, x_0 - wx_1 )\ \BhDef)\ \MocCmb
\end{align}

> fft :: (C -> a -> a -> (a, a)) -> Integer -> V.Vector a -> V.Vector a
> fft butterfly k vs = (V.bitrev . V.pipe1 stage kern) vs
>   where
>     stage   w = V.concat . (V.farm21 segment (twiddles n)) . V.group w
>     segment t = (V.unduals <>) . (V.farm22 (butterfly t) <>) . V.duals
>     kern      = V.iterate k (*2) 2 -- segment lengths
>     n         = V.length vs        -- length of input 

The \texttt{fft} network is instantiated with the function above. Its type signature is:
\begin{equation}\label{eq:fft-type}
  \mathtt{fft} : (\mathbb{C} \rightarrow \alpha^2 \rightarrow \alpha^2) \rightarrow \mathbb{N} \rightarrow \SkelVec{\alpha} \rightarrow \SkelVec{\alpha}  
\end{equation}
and, as it suggests, it is not concerned in the actual functionality implemented, rather it is just a skeleton (higher order function) which instantiates an interconnection network. Its arguments are:
\begin{itemize}
\item $\mathtt{vs}:\SkelVec{\alpha}$ the vector of input samples, where $L(\mathtt{vs})=N$
\item $\mathtt{k}:\mathbb{N}$ the number of butterfly stages, which needs to satisfy the condition $2^{\mathtt{k}} = N$ 
\item $\mathtt{butterfly}:\mathbb{C} \rightarrow \alpha^2 \rightarrow \alpha^2$ which performs the computation suggested by Figure \ref{fig:fft-butterfly}, in different formats, depending on the test case.
\end{itemize}%

> butterfly1 bffunc w = MoC.comb22 (bffunc w)

The function wrapped by the \texttt{butterfly} network is \texttt{bffunc(U)} and needs to be specified differently depending on whether the MoC is timed or untimed. For timed MoCs, it is simply a function on values, but for untimed MoCs it needs to reflect the fact that it operates on multiple tokens, thus we express this in ForSyDe-Atom as a function on lists of values.

> bffuncT w  x0   x1  = ( x0 + w * x1 ,  x0 - w * x1 )
> bffuncU w [x0] [x1] = ([x0 + w * x1], [x0 - w * x1])

Now we can instantiate \texttt{fft} as a parallel process network with:

> fft1SY  :: Integer -> V.Vector (SY.Signal  C) -> V.Vector (SY.Signal  C)
> fft1DE  :: Integer -> V.Vector (DE.Signal  C) -> V.Vector (DE.Signal  C)
> fft1CT  :: Integer -> V.Vector (CT.Signal  C) -> V.Vector (CT.Signal  C)
> fft1SDF :: Integer -> V.Vector (SDF.Signal C) -> V.Vector (SDF.Signal C)
> 
> fft1SY  = fft (butterfly1          bffuncT )
> fft1DE  = fft (butterfly1          bffuncT )
> fft1CT  = fft (butterfly1          bffuncT )
> fft1SDF = fft (butterfly1 (wrapped bffuncU))
>   where wrapped bf w = MoC.ctxt22 (1,1) (1,1) (bf w)
  
\subsection{Case 2: Signal of Vectors}
\label{sec:case-2:-signal}

The second case study treats \texttt{fft} as a function on vectors, executing with the timing semantics dictated by a specified MoC, i.e. wrapped in a MoC process constructor. This way, instead of exposing the parallelism at process network level, it treats it at data level, while synchronization is performed externally, as a block component.

For timed MoCs instantiating a process which performs \texttt{fft} on a vector of values is straightforward: simply pass the \texttt{bffunc} to the \texttt{fft} network, which in turn constitutes the function mapped on a signal by a \texttt{comb11} process constructor. We have shown in Section~\ref{sec:case-1:-vector} how to systematically wrap the function on values with different behavior/timing aspects. This time we will use the library-provided helpers to construct \texttt{comb11} processes with a default behavior.

> butterfly2 w x0 x1 = ( x0 + w * x1 ,  x0 - w * x1 )

> fft2SY  :: Integer -> SY.Signal (V.Vector C) -> SY.Signal (V.Vector C)
> fft2DE  :: Integer -> DE.Signal (V.Vector C) -> DE.Signal (V.Vector C)
> fft2CT  :: Integer -> CT.Signal (V.Vector C) -> CT.Signal (V.Vector C)
>  
> fft2SY k = MoC.comb11 (fft butterfly2 k)
> fft2DE k = MoC.comb11 (fft butterfly2 k)
> fft2CT k = MoC.comb11 (fft butterfly2 k)

-- For untimed MoCs though, a more straightforward approach is to make use of the definition of actors as processes with a production/consumption rate for each output/input. In the case of SDF, we would simply have a process which consumes $2^k$ tokens from a signal (the input samples), and apply the \texttt{fft} function over them.
  
> fft2SDF :: Integer -> SDF.Signal C -> SDF.Signal C
> fft2SDF k = SDF.comb11 (2^k, 2^k, V.fromVector . fft butterfly2 k . V.vector)

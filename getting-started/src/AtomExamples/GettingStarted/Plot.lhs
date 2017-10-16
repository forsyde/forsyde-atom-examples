Up until now, we have made use of the \texttt{Show} instance of the \textsc{ForSyDe-Atom} data types to print out signals on the terminal screen. While this remains the main way to test if a model is working properly, there are alternative ways to plot data. This section introduces the reader to the \href{\utilploturl}{\texttt{ForSyDe.Atom.Utility.Plot}} library of utilities for visualizing signals or other data types.

The functions presented in this section are defined in the following module, which is exported by \texttt{AtomExamples.GettingStarted}.

> module AtomExamples.GettingStarted.Plot where

We will be using the signals defined in the previous section, so let us import the corresponding module:

> import AtomExamples.GettingStarted.Basics

And, as mentioned, we need to import the library with plotting utilities:

> import ForSyDe.Atom.Utility.Plot

Upon consulting the \href{\utilploturl}{API documentation} for this module, you might notice that most utilities input a so-called \texttt{PlotData} type, which is an alias for a complex structure carrying configuration parameters, type information and data samples. Using Haskell's type classes, \textsc{ForSyDe-Atom} is able to provide few polymorphic utilities for converting most of the useful types into \texttt{PlotData}.

For example, the \href{\utilploturl}{\texttt{prepare}} function takes a "plottable" data type (e.g. a signal of values), and a \texttt{Config} type, and returns \texttt{PlotData}. The \texttt{Config} type is merely a record of configuration parameters useful further down in the plotting pipeline. At the time of writing this report\footnote{\textsc{ForSyDe-Atom} v0.2.1}, a configuration record looked like this:

> config =
>   Cfg { path    = "./fig"     -- path where the eventual data files are dumped
>       , file    = "plot"      -- base name of the eventual files generated
>       , rate    = 0.01        -- sampling rate if relevant (e.g. ignored by SY signals).
>                               -- Useful just for e.g. explicit-timed signals.
>       , xmax    = 20          -- maximum x coordinate. Necessary for infinite signals.
>       , labels  = ["s1","s2"] -- labels for all signals passed to be plotted.
>       , verbose = True        -- prints additional messages for each utility.
>       , fire    = True        -- if relevant, fires a plotting or compiling program.
>       , mklatex = True        -- if relevant, dumps a LaTeX script loading the plot.
>       , mkeps   = True        -- if relevant. dumps a PostScript file with the plot.
>       , mkpdf   = True        -- if relevant, dumps a PDF file with the plot.
>       }

\href{\utilploturl}{\texttt{ForSyDe.Atom.Utility.Plot}} provides several of these pre-made configuration objects, which can be modified on-the-fly using Haskell's record syntax, as you will see further on.

Let us see again the signals \texttt{testsig1} and \texttt{testsig2} defined in the previous section:

< λ> testsig1
< {1,2,3,4,5}
< λ> takeS 20 testsig2
< {0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19}

The utility \href{\utilploturl}{\texttt{showDat}} prints out sampled data on the terminal, as pairs of X and Y coordinates:

> show1 = showDat $ prepare config testsig1
> show2 = let cfg = config {xmax=15, labels=["testsig1","testsig2"]}
>         in  showDat $ prepareL cfg [testsig1,testsig2]

< λ> show1
< s1 = 
< 	0   1.0
< 	1   2.0
< 	2   3.0
< 	3   4.0
< 	4   5.0
<
< λ> show2
< testsig1 = 
< 	0   1.0
< 	1   2.0
< 	2   3.0
< 	3   4.0
< 	4   5.0
< 
< testsig2 = 
< 	0   0.0
< 	1   1.0
< 	2   2.0
< 	3   3.0
< 	4   4.0
< 	5   5.0
< 	6   6.0
< 	7   7.0
< 	8   8.0
< 	9   9.0
< 	10   10.0
< 	11   11.0
< 	12   12.0
< 	13   13.0
< 	14   14.0

The function \href{\utilploturl}{\texttt{dumpDat}} dumps the data files in a path specified by the configuration object. Based on the \texttt{config} object instantiated earlier, after calling the following function you should see a new folder called \texttt{fig} in the current path, with two new \texttt{.dat} files.

> dump2 = let cfg = config {xmax=15, labels=["testsig1","testsig2"]}
>         in  dumpDat $ prepareL cfg [testsig1,testsig2]

< λ> dump2
< Dumped testsig1, testsig2 in ./fig
< ["./fig/testsig1.dat","./fig/testsig2.dat"]

The plot library also has a few functions which create and (optionally) fire \href{http://www.gnuplot.info/}{Gnuplot} scripts. In order to make use of them, you need to install the dependencies mentioned in the \href{\utilploturl}{API documentation}. For example, using the function \href{\utilploturl}{\texttt{plotGnu}} creates the following plot:

> plot2 = let cfg = config {xmax=8, labels=["testsig1","testsig2"]}
>         in  plotGnu $ prepareL cfg [testsig1,testsig2]

\input{input/sig-sytestsig1_testsig2-latex}

Different input data creates different types of plots, as we will see in future sections.

One can also generate \LaTeX\ code which is meant to be compiled with the \href{https://github.com/forsyde/forsyde-latex}{\textsc{ForSyDe-}\LaTeX} package, more specifically its signal plotting library. Check the \href{https://github.com/forsyde/forsyde-latex/blob/master/extras/refman.pdf}{user manual} for more details on how to install the dependencies and how to use the library itself. Naturally, there is a function \href{\utilploturl}{\texttt{showLatex}} which prints out the command for a signals environment defined in \href{https://github.com/forsyde/forsyde-latex}{\textsc{ForSyDe-}\LaTeX}:

> latex1 = let cfg = config {xmax=8, labels=["testsig1","testsig2"]}
>          in  showLatex $ prepareL cfg [testsig1,testsig2]

< λ> latex1
<   \begin{signalsSY}[]{8.0}
<     \signalSY[]{1.0:0,2.0:1,3.0:2,4.0:3,5.0:4}
<     \signalSY[]{0.0:0,1.0:1,2.0:2,3.0:3,4.0:4,5.0:5,6.0:6,7.0:7}
<   \end{signalsSY}
<

Also, there is a command \href{\utilploturl}{\texttt{plotLatex}} for generating a standalone \LaTeX\ document and, if possible, compiling it with \texttt{pdflatex}. For example, calling the following function generates the image from \cref{fig:plot-sy}.

> latex2 = let cfg = config {xmax=8, labels=["testsig1","testsig2"]}
>          in  plotLatex $ prepareL cfg [testsig1,testsig2]

\begin{figure}[ht!]\centering
\includegraphics[]{figs/plot-sy}
\label{fig:plot-sy}
\caption{SY signal plot in \textsc{ForSyDe-}\LaTeX\ as a matrix of nodes}
\end{figure}

The SY signal plot is nothing spectacular, but wraps the events in a matrix of nodes which can be embedded into a more complex \textsc{TikZ} figure. Other signals produce other plots. Most generated plots will need manual tweaking in order to look good. Check the \href{https://github.com/forsyde/forsyde-latex/blob/master/extras/refman.pdf}{user manual} on how to customize each plot. 

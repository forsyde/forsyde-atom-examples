# Hybrid CT/DT Models in ForSyDe-Atom

[![License](https://img.shields.io/badge/License-BSD%203--Clause-blue.svg)](https://opensource.org/licenses/BSD-3-Clause)

This project is a collection of examples for analyzing and experimenting with hybrid/AMS models. It assumes the user is familiarized with using the main features of the library (a good resource for that is the [getting-started](../getting-started) project), and delves direclty into modeling affairs. It has been developed with [`forsyde-atom-v0.2.2`](https://github.com/forsyde/forsyde-atom/releases/tag/0.2.2).

The libraries exported by this Haskell package contain literate code for generating the chapter in the [user manual](../manual.pdf) called "Hybrid CT/DT Models in ForSyDe-Atom", and functions that are meant to be used as hands-on examples. These functions should be loaded in an interpreter session and executed in while reading and following the mentioned document.

## Publications

The following publications reference material from this project: 

 * George Ungureanu, José E. G. de Medeiros and Ingo Sander. 2018. Bridging discrete and continuous time models with Atoms. In _Proceedings of the Conference on Design, Automation & Test in Europe_ (DATE '18). Dresden, Germany, March 2018 [ pre-print ]
   - case study: from the generated PDF report, Section _"RC Oscillator"_
   - source: this package, `atom-examples-hybrid`

## Installation and usage

This project is equipped with a `Makefile` to automate fetching the dependencies, installing the package in a sandbox, and generating the documentation locally. Here are the commands available, where marked with an `!` are the rules which perform multiple operations:

	make install       #! resolves dependencies and installs the package in a sandbox
	make api           #  generates the Haddock HTML API documentation
	make report        #  compiles the PDF report from the literate code
	make docs          #! resolves dependencies and generates api and report
	make clean-docs    #  cleans the generated documentation 
	make uninstall     #! cleans the documentation and deletes the sandbox

After installing the package, to open a sandbox interpreter with a specific library loaded (e.g. `AtomExamples.GettingStarted`)

	stack ghci src/AtomExamples/GettingStarted.hs

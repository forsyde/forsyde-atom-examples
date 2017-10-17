# Getting Started with ForSyDe-Atom

This project is a collection of examples for getting started with modelling in ForSyDe-Atom. They show practical usages of the main concepts of ForSyDe-Atom and introduce the main features of this modelling library. It has been developed with [`forsyde-atom-v0.2.1`](https://github.com/forsyde/forsyde-atom/releases/tag/0.2.1).

The libraries exported by this Haskell package contain literate code for generating Chapter 1 in the [user manual](../manual.pdf) "Getting Started with ForSyDe-Atom", and functions that are meant to be used as hands-on examples. These functions should be loaded in an interpreter session and executed in while reading and following the mentioned document.

## Installation and usage

This project is equipped with a `Makefile` to automate fetching the dependencies, installing the package in a sandbox, and generating the documentation locally. Here are the commands available, where marked with an `!` are the rules which perform multiple operations:

    make dependencies  #  fetches and installs the dependencies for this package
	make install       #! resolves dependencies and installs the package in a sandbox
	make api           #  generates the Haddock HTML API documentation
	make report        #  compiles the PDF report from the literate code
	make docs          #! resolves dependencies and generates api and report
	make clean-docs    #  cleans the generated documentation 
	make uninstall     #! cleans the documentation and deletes the sandbox
	make remove        #! uninstalls the project and deletes fetched dependencies

After installing the package, to open a sandbox interpreter with the libraries loadedm you need to run the command

    cabal repl

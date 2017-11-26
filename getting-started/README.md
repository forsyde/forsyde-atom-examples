# Getting Started with ForSyDe-Atom

This project is a collection of examples for getting started with modelling in ForSyDe-Atom. They show practical usages of the main concepts of ForSyDe-Atom and introduce the main features of this modelling library. It has been developed with [`forsyde-atom-v0.2.1`](https://github.com/forsyde/forsyde-atom/releases/tag/0.2.1.1).

The libraries exported by this Haskell package contain literate code for generating the chapter in the [user manual](../manual.pdf) called "Getting Started with ForSyDe-Atom", and functions that are meant to be used as hands-on examples. These functions should be loaded in an interpreter session and executed in while reading and following the mentioned document.

## Publications

The following publications reference material from this project: 

 * George Ungureanu and Ingo Sander. 2017. A layered formal framework for modeling of cyber-physical systems. In _Proceedings of the Conference on Design, Automation & Test in Europe_ (DATE '17). Lausanne, Switzerland, March 2017, pp. 1715–1720. ( [slides][date17-slides] | [doi][date17-doi] | [bib][date17-bib] )
   - case study: from the generated PDF report, Section _"Toy example: a focus on MoCs"_
   - source: this package, `atom-examples-getting-started`

[date17-slides]: https://www.researchgate.net/publication/320004563_Slides_handout_from_DATE%2717_talk
[date17-doi]: https://doi.org/10.23919/DATE.2017.7927270
[date17-bib]: https://people.kth.se/~ugeorge/cite/publications.html#Ungureanu17:DATE

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

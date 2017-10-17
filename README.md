# ForSyDe Atom Examples

This is a common archive for examples and demonstrators for [ForSyDe-Atom](https://github.com/forsyde/forsyde-atom). Each project is distributed as a separate [Cabal](https://www.haskell.org/cabal/)ized library, meant to be installed and tested in its own separate **sandbox**.

## Why?

 * **separate**: because each example has different dependencies, and was developed for different releases of [ForSyDe-Atom](https://github.com/forsyde/forsyde-atom). That is why it is important to run them in separate sandboxed environments.
 * **libraries**: because it is more convenient to run different functions or configurations inside the `ghci` interpreter or a new Haskell file as simple as calling library-exported functions.

## List of examples

Here is what this repository contains:

 * getting-started: an brief introduction to the main ForSyDe-Atom
   concepts and features.
 * fft (TBA)
 * adc (TBA)

## Installation and usage

Each demonstrator contains additional info regarding installation and usage. This section provides general tips on how to operate this repository.

Some general dependencies need to be taken care of prior to fetching and compiling the demonstrators:

 * [git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git) : for fetching the repository and all special dependencies.
 * [GNU make](https://www.gnu.org/software/make/) for using the `Makefile` scripts. On Debian distribution it usually comes with `build-essential`.
 * [the Haskell platform](https://www.haskell.org/platform/) and `cabal-install` for compiling the examples and taking care of dependencies.
 * [a LaTeX compiler](https://www.tug.org/texlive/quickinstall.html) (optional) which provides the commands `pdflatex` and `biber` for compiling the PDF reports and manual from literate source code yourself.

Once the main dependencies have been taken care of, each project needs to be installed individually using the `make` commands. Among other commands, the installation setup of a project is performed by executing

    make install
	
in the root path of the projecy. This creates a sandbox, fetches all specific dependencies and installes the haskell package. Check the `README.md` files in each example for a full documentation of the `make` commands.

After a successful installation you can open an interpreter session with the examples loaded using the command 

    cabal repl

## Documentation

The examples are meant to be executed while reading the report associated with each project. A [PDF manual](manual.pdf) putting together all project reports is periodically compiled and updated.

Each demonstrator comes with additional documentation:

 * **a PDF report**: compiled from the literate source code. Generating the document is done using the `make report` command run from the root of the project. 
 * **an API documentation HTML page**: generated with the command `make api` or simply `cabal haddock` from root of the project. 

Compiling both documents and fetching their dependencies can be performed with the command `make docs` run from the root of the demonstrator.

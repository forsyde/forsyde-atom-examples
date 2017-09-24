ForSyDe Atom Examples
=====================

This is a common archive for examples and demonstrators for [ForSyDe-Atom](https://github.com/forsyde/forsyde-atom). Each project is distributed as a separate [Cabal](https://www.haskell.org/cabal/)ized library, meant to be installed and tested in its own separate **sandbox**.

Why?
----

 * **separate**: because each example has different dependencies, and was developed for different releases of [ForSyDe-Atom](https://github.com/forsyde/forsyde-atom). That is why it is important to run them in separate sandboxed environments.
 * **libraries**: because it is more convenient to run different modules or configurations inside the `ghci` interpreter or a user-defined module as simple as calling library-exported functions.
 
List of dependencies
--------------------

TODO
 
Getting the documentations
--------------------------

A [PDF report](TODO) with all projects is periodically compiled (using the command [`make report`](#list-of-dependencies) from the repository root).

For each demonstrator, there are two documentations:

 * **a PDF report**: compiled from the LaTeX documents and literate code. Generating the document is done with the command [`make report`](#list-of-dependencies) ran from the root of the project. 
 * **an API documentation**: generated with the command [`make report`](#list-of-dependencies) or simply [`cabal haddock`](#list-of-dependencies) from root of the project. 
 
Installing a demonstrator
-------------------------

TODO
 
Running the examples
--------------------

TODO

The Makefile scripts
--------------------

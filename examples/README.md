# camlzip

This example is for the camlzip library

https://opam.ocaml.org/packages/camlzip

# Source file

`bin/main.ml`

# Building and running

`dune exec bin/main.exe zlibcompress infile compressed-outfile`
`dune exec bin/main.exe zlibuncompress compressed-infile outfile`
`dune exec bin/main.exe zipfiles archive-outfile infile1 ... infileN`
`dune exec bin/main.exe ziplist archive-outfile`

(See source for details.)

# Cleaning up

`dune clean`

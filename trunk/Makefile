### Configuration section

# The name of the Zlib library.  Usually -lz
ZLIB_LIB=-lz

# The directory containing the Zlib library (libz.a or libz.so)
ZLIB_LIBDIR=/usr/lib

# The directory containing the Zlib header file (zlib.h)
ZLIB_INCLUDE=/usr/include

# Where to install the library.  By default: sub-directory 'zip' of
# OCaml's standard library directory.
INSTALLDIR=`$(OCAMLC) -where`/zip

### End of configuration section

OCAMLC=ocamlc -g
OCAMLOPT=ocamlopt
OCAMLDEP=ocamldep

OBJS=zlib.cmo zip.cmo gzip.cmo
C_OBJS=zlibstubs.o

all: zip.cma

allopt: zip.cmxa

zip.cma: $(OBJS) libcamlzip.a
	$(OCAMLC) -a -o zip.cma -custom $(OBJS) \
                -cclib -lcamlzip -ccopt -L$(ZLIB_LIBDIR) -cclib $(ZLIB_LIB)

zip.cmxa: $(OBJS:.cmo=.cmx) libcamlzip.a
	$(OCAMLOPT) -a -o zip.cmxa $(OBJS:.cmo=.cmx) \
                -cclib -lcamlzip -ccopt -L$(ZLIB_LIBDIR) -cclib $(ZLIB_LIB)

libcamlzip.a: $(C_OBJS)
	rm -f libcamlzip.a
	ar rc libcamlzip.a $(C_OBJS)

.SUFFIXES: .mli .ml .cmo .cmi .cmx

.mli.cmi:
	$(OCAMLC) -c $<
.ml.cmo:
	$(OCAMLC) -c $<
.ml.cmx:
	$(OCAMLOPT) -c $<
.c.o:
	$(OCAMLC) -c -ccopt -g -ccopt -I$(ZLIB_INCLUDE) $<

clean:
	rm -f *.cm*
	rm -f *.o *.a

install:
	cp zip.cma zip.cmi gzip.cmi zip.mli gzip.mli libcamlzip.a $(DESTDIR)

installopt:
	cp zip.cmxa zip.a zip.cmx gzip.cmx $(DESTDIR)

depend:
	gcc -MM -I$(ZLIB_INCLUDE) *.c > .depend
	ocamldep *.mli *.ml >> .depend

include .depend

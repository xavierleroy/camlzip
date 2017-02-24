### Configuration section

# The name of the Zlib library.  Usually -lz
ZLIB_LIB=-lz

# The directory containing the Zlib library (libz.a or libz.so)
# Leave empty if libz is in a standard linker directory
ZLIB_LIBDIR=
# ZLIB_LIBDIR=/usr/local/lib

# The directory containing the Zlib header file (zlib.h)
# Leave empty if zlib.h is in a standard compiler directory
ZLIB_INCLUDE=
# ZLIB_INCLUDE=/usr/local/include

# Where to install the library.  By default: sub-directory 'zip' of
# OCaml's standard library directory.
INSTALLDIR=`$(OCAMLC) -where`/zip

### End of configuration section

OCAMLC=ocamlc -g -safe-string
OCAMLOPT=ocamlopt -safe-string
OCAMLDEP=ocamldep
OCAMLMKLIB=ocamlmklib

OBJS=zlib.cmo zip.cmo gzip.cmo
C_OBJS=zlibstubs.o

NATDYNLINK := $(shell if [ -f `ocamlc -where`/dynlink.cmxa ]; then echo YES; else echo NO; fi)

ifeq "${NATDYNLINK}" "YES"
CMXS = zip.cmxs
endif

ZLIB_L_OPT=$(if $(ZLIB_LIBDIR),-L$(ZLIB_LIBDIR)) 
ZLIB_I_OPT=$(if $(ZLIB_INCLUDE),-ccopt -I$(ZLIB_INCLUDE)) 

all: libcamlzip.a zip.cma

allopt: libcamlzip.a zip.cmxa $(CMXS)

zip.cma: $(OBJS)
	$(OCAMLMKLIB) -o zip -oc camlzip $(OBJS) \
            $(ZLIB_L_OPT) $(ZLIB_LIB)

zip.cmxa: $(OBJS:.cmo=.cmx)
	$(OCAMLMKLIB) -o zip -oc camlzip $(OBJS:.cmo=.cmx) \
            $(ZLIB_L_OPT) $(ZLIB_LIB)

zip.cmxs: zip.cmxa
	$(OCAMLOPT) -shared -linkall -I ./ -o $@ $^

libcamlzip.a: $(C_OBJS)
	$(OCAMLMKLIB) -oc camlzip $(C_OBJS) \
            $(ZLIB_L_OPT) $(ZLIB_LIB)

.SUFFIXES: .mli .ml .cmo .cmi .cmx

.mli.cmi:
	$(OCAMLC) -c $<
.ml.cmo:
	$(OCAMLC) -c $<
.ml.cmx:
	$(OCAMLOPT) -c $<
.c.o:
	$(OCAMLC) -c -ccopt -g $(ZLIB_I_OPT) $<

clean:
	rm -f *.cm*
	rm -f *.o *.a *.so
	rm -rf doc/

install:
	mkdir -p $(INSTALLDIR)
	cp zip.cma zip.cmi gzip.cmi zlib.cmi zip.mli gzip.mli zlib.mli libcamlzip.a $(INSTALLDIR)
	if test -f dllcamlzip.so; then \
	  cp dllcamlzip.so $(INSTALLDIR); \
          ldconf=`$(OCAMLC) -where`/ld.conf; \
          installdir=$(INSTALLDIR); \
          if test `grep -s -c $$installdir'$$' $$ldconf || :` = 0; \
          then echo $$installdir >> $$ldconf; fi \
        fi

installopt:
	cp zip.cmxa $(CMXS) zip.a zip.cmx gzip.cmx zlib.cmx $(INSTALLDIR)

install-findlib:
	cp META-zip META && \
        ocamlfind install zip META *.mli *.a *.cmi *.cma $(wildcard *.cmx) $(wildcard *.cmxa) $(wildcard *.cmxs) $(wildcard *.so) && \
        rm META
	cp META-camlzip META && \
        ocamlfind install camlzip META && \
        rm META

depend:
	gcc -MM $(ZLIB_I_OPT) *.c > .depend
	ocamldep *.mli *.ml >> .depend

include .depend

doc: *.mli
	mkdir -p doc
	ocamldoc -d doc/ -html *.mli

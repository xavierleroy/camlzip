all: test-testzlib test-minizip test-minigzip

minigzip: ../zip.cmxa minigzip.ml
	ocamlopt -ccopt -g -g -I .. -o minigzip ../zip.cmxa minigzip.ml

test-minigzip: minigzip minigzip.run
	sh ./minigzip.run

minizip: ../zip.cmxa minizip.ml
	ocamlopt -ccopt -g -g -I .. -o minizip unix.cmxa ../zip.cmxa minizip.ml

test-minizip: minizip minizip.run
	sh ./minizip.run

testzlib: ../zip.cmxa testzlib.ml
	ocamlopt -g -I .. -o testzlib ../zip.cmxa testzlib.ml

test-testzlib: testzlib testzlib.run
	sh ./testzlib.run

clean:
	rm -f *.cm*
	rm -f minigzip minizip testzlib

all:
	ocamldoc -html -css-style mystyle.css \
        -I .. ../gzip.mli ../zip.mli

publish:
	git push -u origin gh-pages

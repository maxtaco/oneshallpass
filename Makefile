
default: index.html
all: index.html

lib-min.js : lib.js
	uglifyjs < $< > $@
index.html : index-in.html lib-min.js make.py main.css
	python make.py < $< > $@

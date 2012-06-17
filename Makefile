
default: index.html
all: index.html

lib-min.js : lib.js
	uglifyjs < $< > $@
ui-min.js : ui.js
	uglifyjs < $< > $@
index.html : index-in.html lib-min.js make.py main.css ui-min.js
	python make.py < $< > $@

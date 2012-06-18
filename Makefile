
default: index.html
all: index.html

JSFILT=cat

lib-min.js : lib.js
	$(JSFILT) < $< > $@
ui-min.js : ui.js
	$(JSFILT) < $< > $@
index.html : index-in.html lib-min.js make.py main.css ui-min.js
	python make.py < $< > $@

clean:
	rm -f index.html lib-min.js ui-min.js

.PHONY: clean

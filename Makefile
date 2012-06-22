
default: index.html
all: index.html

JSFILT=cat

%-min.js : %.js
	$(JSFILT) < $< > $@
index.html : index-in.html lib-min.js make.py main.css ui-min.js crypto-min.js
	python make.py < $< > $@

clean:
	rm -f index.html *-min.js

.PHONY: clean

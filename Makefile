
JSMIN=node_modules/.bin/uglifyjs -c -m
BROWSERIFY=node_modules/.bin/browserify -t icsify

JQUERY_VERSION=1.9.0

default: html
html: \
	build/html/index.html \
	build/html/index-big.html \
	build/html/pp.html \
	build/html/pp-big.html \
	build/html/v2.html

all: default

setup: 
	npm install -d

clean:
	rm -rf build

test: 
	for f in test/*.js; do echo "test $$f..."; node $$f; done
	for f in test/*.iced; do echo "test $$f..."; iced $$f; done

build/js-min/%.js: build/js/%.js
	mkdir -p `dirname $@`
	$(JSMIN) < $^ > $@

build/js/jquery.js: includes/jquery-$(JQUERY_VERSION).js
	cat < $< > $@
build/js/dict.js: data/dict.js
	cat < $< > $@

build/js/main.js: src/main.iced
	mkdir -p `dirname $@`
	($(BROWSERIFY) $< > $@~) && mv $@~ $@
build/js/pp.js: src/pp.iced
	mkdir -p `dirname $@`
	($(BROWSERIFY) $< > $@~) && mv $@~ $@

build/html/index.html: html/index.html \
	build/js-min/jquery.js \
	build/js-min/main.js \
	css/main.css 
	mkdir -p `dirname $@`
	(python bin/inline.py -m < $< > $@~) && mv $@~ $@

build/html/index-big.html: html/index.html \
	build/js/jquery.js \
	build/js/main.js \
	css/main.css 
	mkdir -p `dirname $@`
	(python bin/inline.py < $< > $@~) && mv $@~ $@

build/html/pp-big.html: html/pp.html \
	build/js/jquery.js \
	build/js/dict.js \
	build/js/pp.js \
	css/pp.css 
	mkdir -p `dirname $@`
	(python bin/inline.py < $< > $@~) && mv $@~ $@
	
build/html/pp.html: html/pp.html \
	build/js-min/jquery.js \
	build/js-min/dict.js \
	build/js-min/pp.js \
	css/pp.css 
	mkdir -p `dirname $@`
	(python bin/inline.py < $< > $@~) && mv $@~ $@

build/html/v2.html: v2/www/index.html
	cat < $< > $@

%.md: %.md.in
	python bin/footnoter.py < $< > $@

.PHONY: clean depclean test setup

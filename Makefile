
JSMIN=uglifyjs -c -m

CRYPTO_JS_VERSION=3.0.2
PUREPACK_VERSION=v0.0.1
JQUERY_VERSION=1.9.0
ICED_VERSION=1.4.0a

CRYPTO_SRC=deps/crypto-js/src

default: build/html/index.html build/html/index-min.html
all: default
deps: deps-crypto-js

clean:
	rm -rf build

depclean:
	rm -rf deps

deps-crypto-js: $(CRYPTO_SRC)/core.js

$(CRYPTO_SRC)/core.js:
	mkdir -p deps
	cd deps ; \
	if [ -d crypto-js ] ; then \
		(cd crypto-js && svn up); \
	else \
		svn checkout http://crypto-js.googlecode.com/svn/tags/$(CRYPTO_JS_VERSION) crypto-js ; \
	fi

build/js/crypto.js: \
	$(CRYPTO_SRC)/core.js \
	$(CRYPTO_SRC)/cipher-core.js \
	$(CRYPTO_SRC)/x64-core.js \
	$(CRYPTO_SRC)/hmac.js \
	$(CRYPTO_SRC)/sha1.js \
	$(CRYPTO_SRC)/sha512.js \
	$(CRYPTO_SRC)/enc-base64.js \
	$(CRYPTO_SRC)/aes.js 
	mkdir -p `dirname $@`
	cat $^ > $@

build/js-min/%.js: build/js/%.js
	mkdir -p `dirname $@`
	$(JSMIN) < $^ > $@

build/js/iced.js : includes/iced-$(ICED_VERSION).js
	cat < $< > $@
build/js/jquery.js : includes/jquery-$(JQUERY_VERSION).js
	cat < $< > $@

build/js/main.js : src/main.iced
	mkdir -p `dirname $@`
	(iced --bare --print -I none $^ > $@~) && mv $@~ $@

build/iced/%.js : src/lib/%.iced
	mkdir -p `dirname $@`
	(iced --print -I none $^ > $@~) && mv $@~ $@

build/js/lib.js: build/iced/config.js \
	build/iced/derive.js \
	build/iced/document.js \
	build/iced/engine.js \
	build/iced/location.js \
	build/iced/util.js
	mkdir -p `dirname $@`
	(iced bin/stitch.iced build/iced/ > $@~) && mv $@~ $@

build/html/index-min.html: html/index.html \
	build/js-min/lib.js \
	build/js-min/iced.js \
	build/js-min/crypto.js \
	build/js-min/main.js
	mkdir -p `dirname $@`
	(python bin/inline.py -m < $< > $@~) && mv $@~ $@

build/html/index.html: html/index.html \
	build/js/lib.js \
	build/js/iced.js \
	build/js/crypto.js \
	build/js/main.js \
	css/main.css 
	mkdir -p `dirname $@`
	(python bin/inline.py < $< > $@~) && mv $@~ $@

.PHONY = clean depclean


JSMIN=uglifyjs

CRYPTO_JS_VERSION=3.1.2
PUREPACK_VERSION=v0.0.1
JQUERY_VERSION=2.0.0b1

CRYPTO_SRC=deps/crypto-js/src

default: build/html/index.html build/html/index-min.html
all: default
deps: deps-crypto-js deps-purepack deps-jquery

clean:
	rm -rf build

deps-crypto-js:
	cd deps ; \
	if [ -d crypto-js ] ; then \
		(cd crypto-js && svn up); \
	else \
		svn checkout http://crypto-js.googlecode.com/svn/tags/$(CRYPTO_JS_VERSION) crypto-js ; \
	fi

deps-purepack:
	cd deps ; \
	if [ -d purepack ] ; then \
		(cd purepack && git pull origin $(PUREPACK_VERSION) ) ; \
	else \
		( git clone git://github.com/maxtaco/purepack && \
                  cd purepack && \
                  git checkout $(PUREPACK_VERSION) ) \
	fi

deps-jquery:
	cd deps ; \
	if [ -d jquery ]; then \
		(cd jquery && git pull origin $(JQUERY_VERSION) ); \
	else \
		( git clone git://github.com/jquery/jquery && \
                  cd jquery && \
                  git checkout $(JQUERY_VERSION) ) \
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

build/js-min/coffee-script-iced.js : imports/iced/coffee-script-iced.js
	cat < $< > $@

build/js/coffee-script-iced.js : imports/iced/coffee-script-iced.js
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
	build/iced/util.js
	mkdir -p `dirname $@`
	(iced bin/stitch.iced build/iced/ > $@~) && mv $@~ $@

build/html/index-min.html: html/index.html \
	build/js-min/lib.js \
	build/js-min/coffee-script-iced.js \
	build/js-min/crypto.js \
	build/js-min/main.js
	mkdir -p `dirname $@`
	(python bin/inline.py -m < $< > $@~) && mv $@~ $@

build/html/index.html: html/index.html \
	build/js/lib.js \
	build/js/coffee-script-iced.js \
	build/js/crypto.js \
	build/js/main.js
	mkdir -p `dirname $@`
	(python bin/inline.py < $< > $@~) && mv $@~ $@

.PHONY = clean


all: www/index.html README.md www/pp.html
default: www/index.html

JSFILT=uglifyjs

js-min/%-min.js : js/%.js
	$(JSFILT) < $< > $@

js-min/crypto-min.js: crypto/core.js \
	crypto/x64-core.js \
	crypto/hmac.js \
	crypto/sha1.js \
	crypto/sha512.js \
	crypto/enc-base64.js \
	crypto/pbkdf2.js 
	cat $^ | $(JSFILT) > $@

www/index.html: html/index-in.html js-min/lib-min.js build/make.py css/main.css js-min/ui-min.js js-min/crypto-min.js 
	python build/make.py < $< > $@

www/pp.html: html/pp-in.html js-min/crypto-min.js css/pp.css js-min/pp-min.js js-min/dict-min.js
	python build/make.py < $< > $@

test: test/*.js js-min/crypto-min.js
	for f in test/*.js; do echo "test $$f..."; node $$f; done

google-install:
	(cd gae && appcfg.py update one-shall-pass)

install:
	ssh -A max@ws0.oneshallpass.com '( cd oneshallpass && git pull )'

doc: README.md

%.md: %.md.in
	python build/footnoter.py < $< > $@

clean:
	rm -f www/index.html js-min/*-min.js crypt/*-min.js README.md

.PHONY: clean test doc

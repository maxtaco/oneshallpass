
all: www/index.html README.md
default: www/index.html

JSFILT=uglifyjs

%-min.js : %.js
	$(JSFILT) < $< > $@

crypto-min.js: crypto/core.js \
	crypto/x64-core.js \
	crypto/hmac.js \
	crypto/sha512.js \
	crypto/enc-base64.js
	cat $^ | $(JSFILT) > $@

www/index.html : index-in.html lib-min.js build/make.py main.css ui-min.js crypto-min.js 
	python build/make.py < $< > $@

test: test/hmac-sha512-reference.js crypto-min.js
	node $<

install:
	(cd gae && appcfg.py update one-shall-pass)

doc: README.md

%.md: %.md.in
	python build/footnoter.py < $< > $@

clean:
	rm -f www/index.html *-min.js crypt/*-min.js README.md

.PHONY: clean test doc

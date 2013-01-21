
CRYPTO_JS_VERSION=3.1.2
PUREPACK_VERSION=v0.0.1
JQUERY_VERSION=2.0.0b1

deps: deps-crypto-js deps-purepack deps-jquery


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
		(cd purepack && git pull) ; \
	else \
		( git clone git://github.com/maxtaco/purepack && \
                  cd purepack && \
                  git checkout $(PUREPACK_VERSION) ) \
	fi

deps-jquery:
	cd deps ; \
	if [ -d jquery ]; then \
		(cd jquery && git pull ); \
	else \
		( git clone git://github.com/jquery/jquery && \
                  cd jquery && \
                  git checkout $(JQUERY_VERSION) ) \
	fi

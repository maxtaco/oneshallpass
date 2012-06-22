
/* hmac-sha512 */
var CryptoJS=CryptoJS||function(a,g){var c={},b=c.lib={},k=b.Base=function(){function a(){}return{extend:function(h){a.prototype=this;var e=new a;h&&e.mixIn(h);e.$super=this;return e},create:function(){var a=this.extend();a.init.apply(a,arguments);return a},init:function(){},mixIn:function(a){for(var m in a)a.hasOwnProperty(m)&&(this[m]=a[m]);a.hasOwnProperty("toString")&&(this.toString=a.toString)},clone:function(){return this.$super.extend(this)}}}(),n=b.WordArray=k.extend({init:function(a,h){a=
this.words=a||[];this.sigBytes=h!=g?h:4*a.length},toString:function(a){return(a||r).stringify(this)},concat:function(a){var h=this.words,e=a.words,d=this.sigBytes,a=a.sigBytes;this.clamp();if(d%4)for(var b=0;b<a;b++)h[d+b>>>2]|=(e[b>>>2]>>>24-8*(b%4)&255)<<24-8*((d+b)%4);else if(65535<e.length)for(b=0;b<a;b+=4)h[d+b>>>2]=e[b>>>2];else h.push.apply(h,e);this.sigBytes+=a;return this},clamp:function(){var m=this.words,h=this.sigBytes;m[h>>>2]&=4294967295<<32-8*(h%4);m.length=a.ceil(h/4)},clone:function(){var a=
k.clone.call(this);a.words=this.words.slice(0);return a},random:function(m){for(var h=[],b=0;b<m;b+=4)h.push(4294967296*a.random()|0);return n.create(h,m)}}),x=c.enc={},r=x.Hex={stringify:function(a){for(var b=a.words,a=a.sigBytes,e=[],d=0;d<a;d++){var l=b[d>>>2]>>>24-8*(d%4)&255;e.push((l>>>4).toString(16));e.push((l&15).toString(16))}return e.join("")},parse:function(a){for(var b=a.length,e=[],d=0;d<b;d+=2)e[d>>>3]|=parseInt(a.substr(d,2),16)<<24-4*(d%8);return n.create(e,b/2)}},j=x.Latin1={stringify:function(a){for(var b=
a.words,a=a.sigBytes,e=[],d=0;d<a;d++)e.push(String.fromCharCode(b[d>>>2]>>>24-8*(d%4)&255));return e.join("")},parse:function(a){for(var b=a.length,e=[],d=0;d<b;d++)e[d>>>2]|=(a.charCodeAt(d)&255)<<24-8*(d%4);return n.create(e,b)}},J=x.Utf8={stringify:function(a){try{return decodeURIComponent(escape(j.stringify(a)))}catch(b){throw Error("Malformed UTF-8 data");}},parse:function(a){return j.parse(unescape(encodeURIComponent(a)))}},l=b.BufferedBlockAlgorithm=k.extend({reset:function(){this._data=n.create();
this._nDataBytes=0},_append:function(a){"string"==typeof a&&(a=J.parse(a));this._data.concat(a);this._nDataBytes+=a.sigBytes},_process:function(b){var h=this._data,e=h.words,d=h.sigBytes,l=this.blockSize,c=d/(4*l),c=b?a.ceil(c):a.max((c|0)-this._minBufferSize,0),b=c*l,d=a.min(4*b,d);if(b){for(var j=0;j<b;j+=l)this._doProcessBlock(e,j);j=e.splice(0,b);h.sigBytes-=d}return n.create(j,d)},clone:function(){var a=k.clone.call(this);a._data=this._data.clone();return a},_minBufferSize:0});b.Hasher=l.extend({init:function(){this.reset()},
reset:function(){l.reset.call(this);this._doReset()},update:function(a){this._append(a);this._process();return this},finalize:function(a){a&&this._append(a);this._doFinalize();return this._hash},clone:function(){var a=l.clone.call(this);a._hash=this._hash.clone();return a},blockSize:16,_createHelper:function(a){return function(b,e){return a.create(e).finalize(b)}},_createHmacHelper:function(a){return function(b,e){return fa.HMAC.create(a,e).finalize(b)}}});var fa=c.algo={};return c}(Math);
(function(a){var g=CryptoJS,c=g.lib,b=c.Base,k=c.WordArray,g=g.x64={};g.Word=b.extend({init:function(a,b){this.high=a;this.low=b}});g.WordArray=b.extend({init:function(b,c){b=this.words=b||[];this.sigBytes=c!=a?c:8*b.length},toX32:function(){for(var a=this.words,b=a.length,c=[],j=0;j<b;j++){var g=a[j];c.push(g.high);c.push(g.low)}return k.create(c,this.sigBytes)},clone:function(){for(var a=b.clone.call(this),c=a.words=this.words.slice(0),g=c.length,j=0;j<g;j++)c[j]=c[j].clone();return a}})})();
(function(){function a(){return k.create.apply(k,arguments)}var g=CryptoJS,c=g.lib.Hasher,b=g.x64,k=b.Word,n=b.WordArray,b=g.algo,x=[a(1116352408,3609767458),a(1899447441,602891725),a(3049323471,3964484399),a(3921009573,2173295548),a(961987163,4081628472),a(1508970993,3053834265),a(2453635748,2937671579),a(2870763221,3664609560),a(3624381080,2734883394),a(310598401,1164996542),a(607225278,1323610764),a(1426881987,3590304994),a(1925078388,4068182383),a(2162078206,991336113),a(2614888103,633803317),
a(3248222580,3479774868),a(3835390401,2666613458),a(4022224774,944711139),a(264347078,2341262773),a(604807628,2007800933),a(770255983,1495990901),a(1249150122,1856431235),a(1555081692,3175218132),a(1996064986,2198950837),a(2554220882,3999719339),a(2821834349,766784016),a(2952996808,2566594879),a(3210313671,3203337956),a(3336571891,1034457026),a(3584528711,2466948901),a(113926993,3758326383),a(338241895,168717936),a(666307205,1188179964),a(773529912,1546045734),a(1294757372,1522805485),a(1396182291,
2643833823),a(1695183700,2343527390),a(1986661051,1014477480),a(2177026350,1206759142),a(2456956037,344077627),a(2730485921,1290863460),a(2820302411,3158454273),a(3259730800,3505952657),a(3345764771,106217008),a(3516065817,3606008344),a(3600352804,1432725776),a(4094571909,1467031594),a(275423344,851169720),a(430227734,3100823752),a(506948616,1363258195),a(659060556,3750685593),a(883997877,3785050280),a(958139571,3318307427),a(1322822218,3812723403),a(1537002063,2003034995),a(1747873779,3602036899),
a(1955562222,1575990012),a(2024104815,1125592928),a(2227730452,2716904306),a(2361852424,442776044),a(2428436474,593698344),a(2756734187,3733110249),a(3204031479,2999351573),a(3329325298,3815920427),a(3391569614,3928383900),a(3515267271,566280711),a(3940187606,3454069534),a(4118630271,4000239992),a(116418474,1914138554),a(174292421,2731055270),a(289380356,3203993006),a(460393269,320620315),a(685471733,587496836),a(852142971,1086792851),a(1017036298,365543100),a(1126000580,2618297676),a(1288033470,
3409855158),a(1501505948,4234509866),a(1607167915,987167468),a(1816402316,1246189591)],r=[];(function(){for(var b=0;80>b;b++)r[b]=a()})();b=b.SHA512=c.extend({_doReset:function(){this._hash=n.create([a(1779033703,4089235720),a(3144134277,2227873595),a(1013904242,4271175723),a(2773480762,1595750129),a(1359893119,2917565137),a(2600822924,725511199),a(528734635,4215389547),a(1541459225,327033209)])},_doProcessBlock:function(a,b){for(var c=this._hash.words,g=c[0],m=c[1],h=c[2],e=c[3],d=c[4],k=c[5],n=
c[6],c=c[7],X=g.high,K=g.low,Y=m.high,L=m.low,Z=h.high,M=h.low,$=e.high,N=e.low,aa=d.high,O=d.low,ba=k.high,P=k.low,ca=n.high,Q=n.low,da=c.high,R=c.low,s=X,o=K,D=Y,B=L,E=Z,C=M,U=$,F=N,t=aa,p=O,S=ba,G=P,T=ca,H=Q,V=da,I=R,u=0;80>u;u++){var y=r[u];if(16>u)var q=y.high=a[b+2*u]|0,f=y.low=a[b+2*u+1]|0;else{var q=r[u-15],f=q.high,v=q.low,q=(v<<31|f>>>1)^(v<<24|f>>>8)^f>>>7,v=(f<<31|v>>>1)^(f<<24|v>>>8)^(f<<25|v>>>7),A=r[u-2],f=A.high,i=A.low,A=(i<<13|f>>>19)^(f<<3|i>>>29)^f>>>6,i=(f<<13|i>>>19)^(i<<3|f>>>
29)^(f<<26|i>>>6),f=r[u-7],W=f.high,z=r[u-16],w=z.high,z=z.low,f=v+f.low,q=q+W+(f>>>0<v>>>0?1:0),f=f+i,q=q+A+(f>>>0<i>>>0?1:0),f=f+z,q=q+w+(f>>>0<z>>>0?1:0);y.high=q;y.low=f}var W=t&S^~t&T,z=p&G^~p&H,y=s&D^s&E^D&E,ga=o&B^o&C^B&C,v=(o<<4|s>>>28)^(s<<30|o>>>2)^(s<<25|o>>>7),A=(s<<4|o>>>28)^(o<<30|s>>>2)^(o<<25|s>>>7),i=x[u],ha=i.high,ea=i.low,i=I+((t<<18|p>>>14)^(t<<14|p>>>18)^(p<<23|t>>>9)),w=V+((p<<18|t>>>14)^(p<<14|t>>>18)^(t<<23|p>>>9))+(i>>>0<I>>>0?1:0),i=i+z,w=w+W+(i>>>0<z>>>0?1:0),i=i+ea,w=w+
ha+(i>>>0<ea>>>0?1:0),i=i+f,w=w+q+(i>>>0<f>>>0?1:0),f=A+ga,y=v+y+(f>>>0<A>>>0?1:0),V=T,I=H,T=S,H=G,S=t,G=p,p=F+i|0,t=U+w+(p>>>0<F>>>0?1:0)|0,U=E,F=C,E=D,C=B,D=s,B=o,o=i+f|0,s=w+y+(o>>>0<i>>>0?1:0)|0}K=g.low=K+o|0;g.high=X+s+(K>>>0<o>>>0?1:0)|0;L=m.low=L+B|0;m.high=Y+D+(L>>>0<B>>>0?1:0)|0;M=h.low=M+C|0;h.high=Z+E+(M>>>0<C>>>0?1:0)|0;N=e.low=N+F|0;e.high=$+U+(N>>>0<F>>>0?1:0)|0;O=d.low=O+p|0;d.high=aa+t+(O>>>0<p>>>0?1:0)|0;P=k.low=P+G|0;k.high=ba+S+(P>>>0<G>>>0?1:0)|0;Q=n.low=Q+H|0;n.high=ca+T+(Q>>>
0<H>>>0?1:0)|0;R=c.low=R+I|0;c.high=da+V+(R>>>0<I>>>0?1:0)|0},_doFinalize:function(){var a=this._data,b=a.words,c=8*this._nDataBytes,g=8*a.sigBytes;b[g>>>5]|=128<<24-g%32;b[(g+128>>>10<<5)+31]=c;a.sigBytes=4*b.length;this._process();this._hash=this._hash.toX32()},blockSize:32});g.SHA512=c._createHelper(b);g.HmacSHA512=c._createHmacHelper(b)})();
(function(){var a=CryptoJS,g=a.enc.Utf8;a.algo.HMAC=a.lib.Base.extend({init:function(a,b){a=this._hasher=a.create();"string"==typeof b&&(b=g.parse(b));var k=a.blockSize,n=4*k;b.sigBytes>n&&(b=a.finalize(b));for(var x=this._oKey=b.clone(),r=this._iKey=b.clone(),j=x.words,J=r.words,l=0;l<k;l++)j[l]^=1549556828,J[l]^=909522486;x.sigBytes=r.sigBytes=n;this.reset()},reset:function(){var a=this._hasher;a.reset();a.update(this._iKey)},update:function(a){this._hasher.update(a);return this},finalize:function(a){var b=
this._hasher,a=b.finalize(a);b.reset();return b.finalize(this._oKey.clone().concat(a))}})})();


// enc-base64.js
(function () {
    // Shortcuts
    var C = CryptoJS;
    var C_lib = C.lib;
    var WordArray = C_lib.WordArray;
    var C_enc = C.enc;

    /**
     * Base64 encoding strategy.
     */
    var Base64 = C_enc.Base64 = {
        /**
         * Converts a word array to a Base64 string.
         *
         * @param {WordArray} wordArray The word array.
         *
         * @return {string} The Base64 string.
         *
         * @static
         *
         * @example
         *
         *     var base64String = CryptoJS.enc.Base64.stringify(wordArray);
         */
        stringify: function (wordArray) {
            // Shortcuts
            var words = wordArray.words;
            var sigBytes = wordArray.sigBytes;
            var map = this._map;

            // Clamp excess bits
            wordArray.clamp();

            // Convert
            var base64Chars = [];
            for (var i = 0; i < sigBytes; i += 3) {
                var byte1 = (words[i >>> 2]       >>> (24 - (i % 4) * 8))       & 0xff;
                var byte2 = (words[(i + 1) >>> 2] >>> (24 - ((i + 1) % 4) * 8)) & 0xff;
                var byte3 = (words[(i + 2) >>> 2] >>> (24 - ((i + 2) % 4) * 8)) & 0xff;

                var triplet = (byte1 << 16) | (byte2 << 8) | byte3;

                for (var j = 0; (j < 4) && (i + j * 0.75 < sigBytes); j++) {
                    base64Chars.push(map.charAt((triplet >>> (6 * (3 - j))) & 0x3f));
                }
            }

            // Add padding
            var paddingChar = map.charAt(64);
            if (paddingChar) {
                while (base64Chars.length % 4) {
                    base64Chars.push(paddingChar);
                }
            }

            return base64Chars.join('');
        },
        // Modified for no symbols, at the cost of some entropy!
        _map: 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789ABC'
    };
}());
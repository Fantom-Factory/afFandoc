using fandoc::DocElem

** An interface for resolving URI links.
@Js
mixin LinkResolver {

	** Resolve the given 'url'.
	abstract Uri? resolve(DocElem elem, Str? scheme, Uri url)

	** Creates a 'LinkResolver' from the given fn. 
	static new fromFn(|DocElem elem, Str? scheme, Uri url -> Uri?| fn) {
		FuncLinkResolver(fn)
	}
	
	** Returns a basic 'LinkResolver' that just returns the given 'url'. 
	static LinkResolver passThroughResolver() {
		fromFn() |DocElem elem, Str? scheme, Uri url -> Uri?| { url }
	}
	
	** Returns a 'LinkResolver' that returns the given 'url' should it be prefixed with a '#'. 
	static LinkResolver idPassThroughResolver() {
		fromFn() |DocElem elem, Str? scheme, Uri url -> Uri?| {
			url.toStr.startsWith("#") ? url : null
		}
	}

	** Returns a 'LinkResolver' that returns the given 'url' should it be qualified with a 
	** common scheme such as: 'http', 'https', 'ftp', 'data'. 
	static LinkResolver schemePassThroughResolver(Str[] schemes := "http https ftp data".split) {
		fromFn() |DocElem elem, Str? scheme, Uri url -> Uri?| {
			schemes.contains(scheme ?: "") ? url : null
		}
	}

	** Returns a 'LinkResolver' that returns the given 'url' should it be path only and path absolute. 
	static LinkResolver pathAbsPassThroughResolver() {
		fromFn() |DocElem elem, Str? scheme, Uri url -> Uri?| {
			url.isRel && url.host == null && url.isPathAbs ? url : null
		}
	}

	** Returns a 'LinkResolver' that returns an 'errorUrl' should the given 'url' have a scheme of 'javascript:'.  
	static LinkResolver javascriptErrorResolver(Uri errorUrl := `/error`) {
		fromFn() |DocElem elem, Str? scheme, Uri url -> Uri?| {
			scheme == "javascript" ? errorUrl : null
		}
	}
}

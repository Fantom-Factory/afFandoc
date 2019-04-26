using fandoc::DocElem

** An interface for resolving URI links.
@Js
mixin LinkResolver {

	** Resolve the given 'url'.
	abstract Uri? resolve(DocElem elem, Str? scheme, Uri url)

	** Returns a basic 'LinkResolver' that just returns the given 'url'. 
	static LinkResolver passThroughResolver() {
		FuncLinkResolver() |DocElem elem, Str? scheme, Uri url -> Uri?| { url }
	}
	
	** Returns a 'LinkResolver' that returns the given 'url' should it be prefixed with a '#'. 
	static LinkResolver idPassThroughResolver() {
		FuncLinkResolver() |DocElem elem, Str? scheme, Uri url -> Uri?| {
			url.toStr.startsWith("#") ? url : null
		}
	}

	** Returns a 'LinkResolver' that returns the given 'url' should it be qualified with a 
	** common scheme such as: 'http', 'https', 'ftp', 'data'. 
	static LinkResolver schemePassThroughResolver(Str[] schemes := "http https ftp data".split) {
		FuncLinkResolver() |DocElem elem, Str? scheme, Uri url -> Uri?| {
			schemes.contains(scheme ?: "") ? url : null
		}
	}

	** Returns a 'LinkResolver' that returns the given 'url' should it be path only and path absolute. 
	static LinkResolver pathAbsPassThroughResolver() {
		FuncLinkResolver() |DocElem elem, Str? scheme, Uri url -> Uri?| {
			url.isPathOnly && url.isPathAbs ? url : null
		}
	}

	** Returns a 'LinkResolver' that returns an 'errorUrl' should the given 'url' have a scheme of 'javascript:'.  
	static LinkResolver javascriptErrorResolver(Uri errorUrl := `/error`) {
		FuncLinkResolver() |DocElem elem, Str? scheme, Uri url -> Uri?| {
			scheme == "javascript" ? errorUrl : null
		}
	}
}

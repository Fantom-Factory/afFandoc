using fandoc::DocElem
using fandoc::DocNodeId
using fandoc::Link
using fandoc::Image

** An interface for resolving URI links.
@Js
mixin LinkResolver {

	** Resolve the given 'url'.
	abstract Uri? resolve(DocElem elem, Uri url)

	** Creates a 'LinkResolver' from the given fn. 
	static new fromFn(|DocElem elem, Uri url -> Uri?| fn) {
		FnLinkResolver(fn)
	}
	
	** Returns the original "camelCased" scheme associated with the given Elem's URI.
	** 
	** This is useful because Fantom's Uri lower cases the scheme - making the extraction of pod names near impossible!
	static Str? findScheme(DocElem elem) {
		url := null as Str
		switch (elem.id) {
			case DocNodeId.link		: url = ((Link ) elem).uri
			case DocNodeId.image	: url = ((Image) elem).uri
			default					: throw UnsupportedErr("Only link and image elems are supported: ${elem.id}")
		}
		if (url == null) return null
		uri		:= Uri(url, false)
		scheme	:= uri.scheme == null ? null : url[0..<uri.scheme.size]
		return scheme
	}
	
	** Returns a basic 'LinkResolver' that just returns the given 'url'. 
	static LinkResolver passThroughResolver() {
		fromFn() |DocElem elem, Uri url -> Uri?| { url }
	}
	
	** Returns a 'LinkResolver' that returns the given 'url' should it be prefixed with a '#'. 
	static LinkResolver idPassThroughResolver() {
		fromFn() |DocElem elem, Uri url -> Uri?| {
			url.toStr.startsWith("#") ? url : null
		}
	}

	** Returns a 'LinkResolver' that returns the given 'url' should it be qualified with a 
	** common scheme such as: 'http', 'https', 'ftp', 'data'. 
	static LinkResolver schemePassThroughResolver(Str[] schemes := "http https ftp data".split) {
		fromFn() |DocElem elem, Uri url -> Uri?| {
			schemes.contains(url.scheme ?: "") ? url : null
		}
	}

	** Returns a 'LinkResolver' that returns the given 'url' should it be path only and path absolute. 
	static LinkResolver pathAbsPassThroughResolver() {
		fromFn() |DocElem elem, Uri url -> Uri?| {
			url.isRel && url.host == null && url.isPathAbs ? url : null
		}
	}

	** Returns a 'LinkResolver' that returns an 'errorUrl' should the given 'url' have a scheme of 'javascript:'.  
	static LinkResolver javascriptErrorResolver(Uri errorUrl := `/error`) {
		fromFn() |DocElem elem, Uri url -> Uri?| {
			url.scheme == "javascript" ? errorUrl : null
		}
	}
}

@Js
internal class FnLinkResolver : LinkResolver {
	|DocElem, Uri -> Uri?| func
	
	new make(|DocElem, Uri -> Uri?| func) {
		this.func = func
	}
	
	override Uri? resolve(DocElem elem, Uri url) {
		func(elem, url)
	}	
}


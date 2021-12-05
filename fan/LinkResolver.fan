
** An interface for resolving URI links.
@Js
mixin LinkResolver {

	** Resolve the given 'url'.
	abstract Uri? resolve(Str? scheme, Uri url)

	** Creates a 'LinkResolver' from the given fn. 
	static new fromFn(|Str? scheme, Uri url -> Uri?| fn) {
		FnLinkResolver(fn)
	}
	
	** Returns a 'LinkResolver' that returns links to documentation on the Fantom website. 
	** 
	** Supports qualified Fantom links as defined in `compilerDoc::DocLink` and resolves them to the 
	** Fantom website. (@ [http://fantom.org/doc/]`http://fantom.org/doc/`)
	**
	**   table:
	**   Format             Display     Links To
	**   -----------------  -------     ---------------------------------
	**   pod::index         pod         absolute link to pod index
	**   pod::pod-doc       pod         absolute link to pod doc chapter
	**   pod::Type          Type        absolute link to type qname
	**   pod::Types.slot    Type.slot   absolute link to slot qname
	**   pod::Chapter       Chapter     absolute link to book chapter
	**   pod::Chapter#frag  Chapter     absolute link to book chapter anchor
	** 	
	static LinkResolver fandocResolver() {
		FandocLinkResolver()
	}
	
	** Returns a basic 'LinkResolver' that just returns the given 'url'. 
	static LinkResolver passThroughResolver() {
		fromFn() |Str? scheme, Uri url -> Uri?| { url }
	}
	
	** Returns a 'LinkResolver' that returns the given 'url' should it be prefixed with a '#'. 
	static LinkResolver idPassThroughResolver() {
		fromFn() |Str? scheme, Uri url -> Uri?| {
			url.toStr.startsWith("#") ? url : null
		}
	}

	** Returns a 'LinkResolver' that returns the given 'url' should it be qualified with a 
	** common scheme such as: 'http', 'https', 'ftp', 'data'. 
	static LinkResolver schemePassThroughResolver(Str[] schemes := "http https ftp data".split) {
		fromFn() |Str? scheme, Uri url -> Uri?| {
			schemes.contains(url.scheme ?: "") ? url : null
		}
	}

	** Returns a 'LinkResolver' that returns the given 'url' should it be path only and path absolute. 
	static LinkResolver pathAbsPassThroughResolver() {
		fromFn() |Str? scheme, Uri url -> Uri?| {
			url.isRel && url.host == null && url.isPathAbs ? url : null
		}
	}

	** Returns a 'LinkResolver' that returns an 'errorUrl' should the given 'url' have a scheme of 'javascript:'.  
	static LinkResolver javascriptErrorResolver(Uri errorUrl := `/error`) {
		fromFn() |Str? scheme, Uri url -> Uri?| {
			url.scheme == "javascript" ? errorUrl : null
		}
	}
}

@Js
internal class FnLinkResolver : LinkResolver {
	|Str?, Uri -> Uri?| func
	
	new make(|Str?, Uri -> Uri?| func) {
		this.func = func
	}
	
	override Uri? resolve(Str? scheme, Uri url) {
		func(scheme, url)
	}	
}


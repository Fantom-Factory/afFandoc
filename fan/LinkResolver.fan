
** An interface for resolving URI links.
@Js
mixin LinkResolver {

	** Resolve the given 'uri'.
	abstract Uri? resolve(Str? scheme, Uri uri)

	** Creates a 'LinkResolver' from the given fn. 
	static new fromFn(|Str? scheme, Uri uri -> Uri?| fn) {
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
	
	** Returns a basic 'LinkResolver' that just returns the given 'uri'. 
	static LinkResolver passThroughResolver() {
		fromFn() |Str? scheme, Uri uri -> Uri?| { uri }
	}
	
	** Returns a 'LinkResolver' that returns the given 'uri' should it be prefixed with a '#'. 
	static LinkResolver idPassThroughResolver() {
		fromFn() |Str? scheme, Uri uri -> Uri?| {
			uri.toStr.startsWith("#") ? uri : null
		}
	}

	** Returns a 'LinkResolver' that returns the given 'uri' should it be qualified with a 
	** common scheme such as: 'http', 'https', 'ftp', 'data'. 
	static LinkResolver schemePassThroughResolver(Str[] schemes := "http https ftp data javascript".split) {
		fromFn() |Str? scheme, Uri uri -> Uri?| {
			schemes.contains(uri.scheme ?: "") ? uri : null
		}
	}

	** Returns a 'LinkResolver' that returns the given 'uri' should it be path only and path absolute. 
	static LinkResolver pathAbsPassThroughResolver() {
		fromFn() |Str? scheme, Uri uri -> Uri?| {
			uri.isRel && uri.host == null && uri.isPathAbs ? uri : null
		}
	}
	
	** Returns a 'LinkResolver' that validates CSS links - use in conjunction with 'CssLinkProcessor'.
	** 
	** The given func just needs to call 'HtmlDocWriter.resolveHref()'.
	static LinkResolver cssLinkResolver(|Str? scheme, Uri uri->Uri?| resolverLinkFn) {
		CssLinkResolver(resolverLinkFn)
	}
}

@Js
internal class FnLinkResolver : LinkResolver {
	|Str?, Uri -> Uri?| func
	
	new make(|Str?, Uri -> Uri?| func) {
		this.func = func
	}
	
	override Uri? resolve(Str? scheme, Uri uri) {
		func(scheme, uri)
	}	
}


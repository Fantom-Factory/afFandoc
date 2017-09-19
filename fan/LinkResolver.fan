using fandoc::DocElem

mixin LinkResolver {

	abstract Uri? resolve(DocElem elem, Str? scheme, Uri url)

	static LinkResolver passThroughResolver() {
		FuncLinkResolver() |DocElem elem, Str? scheme, Uri url -> Uri?| { url }
	}
	
	static LinkResolver idPassThroughResolver() {
		FuncLinkResolver() |DocElem elem, Str? scheme, Uri url -> Uri?| {
			url.toStr.startsWith("#") ? url : null
		}
	}

	static LinkResolver schemePassThroughResolver(Str[] schemes := "http https ftp data".split) {
		FuncLinkResolver() |DocElem elem, Str? scheme, Uri url -> Uri?| {
			schemes.contains(scheme ?: "") ? url : null
		}
	}

	static LinkResolver pathAbsPassThroughResolver() {
		FuncLinkResolver() |DocElem elem, Str? scheme, Uri url -> Uri?| {
			url.isPathAbs ? url : null
		}
	}
}

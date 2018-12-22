using fandoc::DocElem

** A generic link resolver that may be customised with a function.
@Js
class FuncLinkResolver : LinkResolver {
	|DocElem, Str?, Uri -> Uri?| func
	
	new make(|DocElem, Str?, Uri -> Uri?| func) {
		this.func = func
	}
	
	override Uri? resolve(DocElem elem, Str? scheme, Uri url) {
		func(elem, scheme, url)
	}	
}

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
//**   Type               Type        pod relative link to type
//**   Type.slot          Type.slot   pod relative link to slot
//**   slot               slot        type relative link to slot
//**   Chapter            Chapter     pod relative link to book chapter
//**   Chapter#frag       Chapter     pod relative link to chapter anchor
//**   #frag              heading     chapter relative link to anchor
@Js
class FandocLinkResolver : LinkResolver {
	Uri		baseUrl			:= `http://fantom.org/doc/`
	Str[]	corePodNames	:= "docIntro docLang docFanr docTools build compiler compilerDoc compilerJava compilerJs concurrent dom domkit email fandoc fanr fansh flux fluxText fwt gfx graphics icons inet obix sql syntax sys testCompiler testJava testNative testSys util web webfwt webmod wisp xml".split

	override Uri? resolve(DocElem elem, Str? scheme, Uri url) {
		// link to Fantom Types - Damn you Fantom for creating this crappy syntax!
		if (scheme == null || !url.pathStr.startsWith(":"))
			return null

		pod  := scheme	// uri.scheme lowercases everything... damn!
		if (!corePodNames.contains(pod))
			return null
		
		path := url.pathStr[1..-1].split('.')
		type := path[0] == "index" || path[0] == "pod-doc" ? "" : path[0]
		slot := (path.getSafe(1) ?: url.frag) ?: Str.defVal
		link := baseUrl.plusSlash + (`${pod}/${type}` + (slot.isEmpty ? `` : `#${slot}`))
		return link
	}
}
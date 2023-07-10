using fandoc::DocElem

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
@Js @NoDoc
const class FandocLinkResolver : LinkResolver {
	const Uri	baseUrl			:= `https://fantom.org/doc/`
	const Str[]	corePodNames	:= "asn1 build compiler compilerDoc compilerJava compilerJs concurrent crypto cryptoJava docDomkit docFanr docIntro docLang docTools dom domkit email fandoc fanr fansh flux fluxText fwt gfx graphics graphicsJava icons inet math sql syntax sys util web webfwt webmod wisp xml yaml".split

	override Uri? resolve(Str? scheme, Uri uri) {
		// link to Fantom Types - Damn you Fantom for creating this crappy syntax!
		if (uri.scheme == null || !uri.pathStr.startsWith(":"))
			return null

		pod  := scheme	// uri.scheme lowercases everything... damn!
		if (pod == null)
			return null

		if (!corePodNames.contains(pod))
			return null
		
		path := uri.pathStr[1..-1].split('.')
		type := path[0] == "index" || path[0] == "pod-doc" ? "" : path[0]
		slot := (path.getSafe(1) ?: uri.frag) ?: Str.defVal
		link := baseUrl.plusSlash + (`${pod}/${type}` + (slot.isEmpty ? `` : `#${slot}`))
		return link
	}
}

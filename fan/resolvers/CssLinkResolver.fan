
@Js
internal class CssLinkResolver : LinkResolver {
	
	private |Str?, Uri->Uri?| resolverLinkFn
	
	new make(|Str?, Uri->Uri?| resolverLinkFn) {
		this.resolverLinkFn = resolverLinkFn
	}
	
	override Uri? resolve(Str? scheme, Uri url) {
		href := url.toStr
		if (href.startsWith(".") == false)
			return null
		
		data := CssPrefixProcessor.parseStying(href)
		link := data["text"]?.trimToNull
		if (link == null)
			// non-null to ward off the unresolvedLink processor 
			return url

		// if we have an actual URL, resolve / validate it
		scheme = link.contains(":")
			? link[0..<link.index(":")]
			: null
		
		oldUri := Uri(link, false)
		if (oldUri == null)
			return url

		newUrl := resolverLinkFn(scheme, oldUri)
		
		// it's a hidden bad link
		if (newUrl == null)
			return null
		
		style := href[0..<-link.size]
		linky := style + newUrl
		return linky.toUri
	}
}


@Js
internal const class CssLinkProcessor : ElemProcessor {
	
	override Obj? process(HtmlElem elem) {
		if (elem.name != "a") return null
	
		href := elem.getUri("href")?.toStr
		if (href == null || href.startsWith(".") == false)
			return null
		
		data := CssPrefixProcessor.parseStying(href)
		
		link := data["text"].trim
		if (link.isEmpty) {
			elem.set("href", null)
			elem.rename("span")
		} else
			elem.set("href", link)
	
		if (data["class"] != null)
			data["class"].split.each { elem.addClass(it) }
	
		if (data["style"] != null)
			elem["style"] = data["style"]

		return null
	}
}

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
		
		link := data["text"].trim
		if (link.isEmpty)
			return url		// non-null to keep the invalidLink processor away 

		// if we have an actual URL, resolve / validate it
		scheme = link.contains(":")
			? link[0..<link.index(":")]
			: null

		newUrl := resolverLinkFn(scheme, link.toUri)
		
		// it's a hidden bad link
		if (newUrl == null)
			return null
		
		style := href[0..<-link.size]
		linky := style + newUrl
		return linky.toUri
	}
}

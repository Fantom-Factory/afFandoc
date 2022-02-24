
@Js
internal const class CssLinkProcessor : ElemProcessor {
	
	override Obj? process(HtmlElem elem) {
		if (elem.name != "a") return null
	
		// open external links in a new tab
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

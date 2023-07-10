using fandoc::DocElem

@Js
internal const class CssLinkProcessor : ElemProcessor {
	
	override Obj? process(HtmlElem elem, DocElem src) {
		if (elem.name != "a") return null
	
		href := elem.getUri("href")?.toStr
		if (href == null || href.startsWith(".") == false)
			return null
	
		link := CssPrefixProcessor.apply(elem, href)
		
		// if there's no link, 
		if (link == null) {
			elem.set("href", null)
			elem.rename("span")
		} else
			elem.set("href", link)
		
		return null
	}
}

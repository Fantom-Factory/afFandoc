using fandoc::DocElem

@Js
internal const class ExternalLinkProcessor : ElemProcessor {
	
	override Obj? process(HtmlElem elem, DocElem src) {
		if (elem.name != "a") return null
		
		// open external links in a new tab
		href := elem.getUri("href")
		if (href?.scheme != null && href?.auth != null)
			elem["target"] = "_blank"

		return null
	}
}

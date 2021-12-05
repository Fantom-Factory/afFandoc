
@Js
internal const class PdfLinkProcessor : ElemProcessor {
	
	override Obj? process(HtmlElem elem) {
		if (elem.name != "a") return null
		
		// open external links in a new tab
		href := elem.getUri("href")
		if (href?.ext == "pdf")
			elem["target"] = "_blank"

		return null
	}
}


@Js
internal const class ExternalLinkProcessor : ElemProcessor {
	
	override Obj? process(HtmlElem elem) {
		if (elem.name != "a") return null
		
		// open external links in a new tab
		href := Uri.decode(elem["href"], false)
		if (href?.scheme != null && href?.auth != null)
			elem["target"] = "_blank"

		return null
	}
}

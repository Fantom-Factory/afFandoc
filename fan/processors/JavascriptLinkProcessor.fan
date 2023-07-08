using fandoc::DocElem

@Js
internal const class JavascriptLinkProcessor : ElemProcessor {

	override Obj? process(HtmlElem elem, DocElem src) {
		href := elem.getUri("href")

		if (href?.scheme == "javascript") {
			elem["href"] = "#"
			elem["data-javascriptLink"] = ""
		}

		return null
	}
}

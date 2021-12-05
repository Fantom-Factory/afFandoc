
@Js
internal const class MailtoProcessor : ElemProcessor {
	
	override Obj? process(HtmlElem elem) {
		if (elem.name != "a") return null
	
		href := elem.getUri("href")
		path := href?.pathStr
		if (href?.scheme == "mailto") {
			elem["href"]			= "#"
			elem["data-unscramble"]	= path.reverse.toBuf.toBase64Uri.reverse
			if (elem.text == path || elem.text == href.encode)
				elem.text = "-" * path.size
		}

		return null
	}
}

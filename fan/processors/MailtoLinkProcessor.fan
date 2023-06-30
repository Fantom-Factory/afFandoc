
@Js
internal const class MailtoProcessor : ElemProcessor {
	
	private const Str attr
	
	new make(Str attr) {
		this.attr = attr
	}
	
	override Obj? process(HtmlElem elem) {
		if (elem.name != "a") return null
	
		href := elem.getUri("href")
		path := href?.pathStr
		if (href?.scheme == "mailto") {
			elem["href"]			= "#"
			elem[attr]	= path.reverse.toBuf.toBase64Uri.reverse
			if (elem.text == path || elem.text == href.encode)
				elem.text = "-" * path.size
			
			// https://jodyvanv.com/mailto-links-not-working-on-google-chrome-android/
			elem["target"]	= "_top"
			elem["rel"]		= "nofollow"
		}

		return null
	}
}


@Js
internal class VimeoImageProcessor : ElemProcessor {
	
	override Obj? process(HtmlElem elem) {
		if (elem.name != "img") return null

		// re-write Vimeo share URLs - https://vimeo.com/11712103
		uri := elem["src"].toUri
		if (uri.host == "vimeo.com") {
			frag  := uri.frag
			query := uri.query
			uri = `https://player.vimeo.com/video/` + uri.pathOnly.relTo(`/`)
			if (frag != null)
				uri = `${uri}#${frag}`
			if (query.size > 0)
				uri = uri.plusQuery(query)
		}

		// Vimeo Videos
		if (uri.host == "player.vimeo.com" && uri.path.first == "video") {
			// make sure the size is one that's recognised
			aspect	:= (elem["width"] ?: "") + "by" + (elem["height"] ?: "")
			if (!"21by9 16by9 4by3 1by1".split.contains(aspect))
				aspect = "16by9"

			return HtmlElem("div") {
				it.addClass("vimeoVideo d-print-none embed-responsive embed-responsive-${aspect}")
				HtmlElem("iframe") {
					it.addClass("embed-responsive-item")
					it["src"]				= uri
					it["allowfullscreen"]	= ""
					it["allow"]				= "fullscreen"
					it["style"]				= "border: none;"
					it["title"]				= elem["alt"]
				},
			}
		}
		
		return null
	}
}

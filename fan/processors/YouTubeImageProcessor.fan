
@Js
internal class YouTubeImageProcessor : ElemProcessor {
	
	override Obj? process(HtmlElem elem) {
		if (elem.name != "img") return null

		// re-write YouTube share URLs - https://youtu.be/2SURpUQzUsE
		uri := elem["src"].toUri
		if (uri.host == "youtu.be") {
			query := uri.query
			uri = `https://www.youtube.com/embed/` + uri.pathOnly.relTo(`/`)
			if (query.size > 0)
				uri = uri.plusQuery(query)
		}
		
		// YouTube Videos
		if (uri.host == "www.youtube.com" && uri.path.first == "embed") {
			// make sure the size is one that's recognised
			aspect	:= (elem["size"] ?: "16x9").replace("x", "by")				
			if (!"21by9 16by9 4by3 1by1".split.contains(aspect))
				aspect = "16by9"

			return HtmlElem("div") {
				it.addClass("youtubeVideo d-print-none embed-responsive embed-responsive-${aspect}")
				HtmlElem("iframe") {
					it.addClass("embed-responsive-item")
					it["src"]				= uri
					it["allowfullscreen"]	= ""
					it["allow"]				= "fullscreen"
					it["style"]				= "border: none;"
				},
			}
		}
		
		return null
	}
}

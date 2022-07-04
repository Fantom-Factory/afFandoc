
**
** https://www.youtube.com/embed/2SURpUQzUsE
** https://youtu.be/2SURpUQzUsE
@Js
internal const class YouTubeBsProcessor : ElemProcessor {
	
	override Obj? process(HtmlElem elem) {
		if (elem.name != "img") return null

		// re-write YouTube share URLs - https://youtu.be/2SURpUQzUsE
		uri := elem.getUri("src")
		if (uri == null) return null

		if (uri.host == "youtu.be") {
			frag  := uri.frag
			query := uri.query
			uri = `https://www.youtube.com/embed/` + uri.pathOnly.relTo(`/`)
			if (frag != null)
				uri = `${uri}#${frag}`
			if (query.size > 0)
				uri = uri.plusQuery(query)
		}
		
		// YouTube Videos
		if (uri.host == "www.youtube.com" && uri.path.first == "embed") {

			// make sure the size is one that's recognised
			aspect	:= (elem["width"] ?: "") + "by" + (elem["height"] ?: "")
			if (!"21by9 16by9 4by3 1by1".split.contains(aspect))
				aspect = "16by9"

			// we always forget that <div> CANNOT be nested inside <p>
			if (elem.parent?.elem?.name == "p")
				elem.parent.elem.rename("div")

			return HtmlElem("div") {
				it.addClass("youtubeVideo d-print-none embed-responsive embed-responsive-${aspect}")

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

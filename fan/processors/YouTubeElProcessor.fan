
**
** https://www.youtube.com/embed/2SURpUQzUsE
** https://youtu.be/2SURpUQzUsE
@Js
internal const class YouTubeElProcessor : ElemProcessor {
	
	override Obj? process(HtmlElem elem) {
		if (elem.name != "img") return null

		uri := elem.getUri("src")
		if (uri == null) return null

		// re-write the standard "watch" URLs
		if (uri.host == "www.youtube.com" && uri.path.first == "watch") {
			frag  := uri.frag
			query := uri.query
			vidId := uri.query["v"]
			if (vidId == null)
				return null
			uri = `https://www.youtube.com/embed/${vidId}`
			if (frag != null)
				uri = `${uri}#${frag}`
			query = query.rw
			query.remove("v")
			if (query.size > 0)
				uri = uri.plusQuery(query)
		}

		// re-write the standard "share" URLs - https://youtu.be/2SURpUQzUsE
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
			aspect	:= (elem["width"] ?: "") + "x" + (elem["height"] ?: "")
			if (!"21x9 16x9 4x3 1x1".split.contains(aspect))
				aspect = "16x9"
			
			width  := aspect.split('x')[0]
			height := aspect.split('x')[1]

			// we always forget that <div> CANNOT be nested inside <p>
			if (elem.parent?.elem?.name == "p")
				elem.parent.elem.rename("div")

			// el-frame may be constrained in size by setting a max-width on .youtubeVideo
			elem.parent?.elem?.addClass("youtubeVideo")
	
			return HtmlElem("div") {
				it.addClass("el-frame")
				it.set("style", "--el-frame-width:${width}; --el-frame-height:${height}")
				
				HtmlElem("iframe") {
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

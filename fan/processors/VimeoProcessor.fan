
** https://vimeo.com/11712103
@Js
internal const class VimeoElProcessor : ElemProcessor {
	
	override Obj? process(HtmlElem elem) {
		if (elem.name != "img") return null

		// re-write Vimeo share URLs - https://vimeo.com/11712103
		uri := elem.getUri("src")
		if (uri == null) return null

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
			aspect	:= (elem["width"] ?: "") + "x" + (elem["height"] ?: "")
			if (!"21x9 16x9 4x3 1x1".split.contains(aspect))
				aspect = "16x9"
			
			width  := aspect.split('x')[0]
			height := aspect.split('x')[1]

			// we always forget that <div> CANNOT be nested inside <p>
			if (elem.parent?.elem?.name == "p")
				elem.parent.elem.rename("div")

			// el-frame may be constrained in size by setting a max-width on .vimeoVideo
			elem.parent?.elem?.addClass("vimeoVideo")

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

using fandoc::DocElem
using fandoc::Image

**
** https://www.youtube.com/embed/2SURpUQzUsE
** https://youtu.be/2SURpUQzUsE
@Js
internal const class YouTubeProcessor : ElemProcessor {
	
	override Obj? process(HtmlElem html, DocElem src) {
		if (html.name != "img") return null

		uri := html.getUri("src")
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
	
			// el-frame may be constrained in size by setting a max-width on .youtubeVideo
			html.parent?.elem?.addClass("youtubeVideo")

			// we always forget that <div> CANNOT be nested inside <p>
			if (html.parent?.elem?.name == "p")
				html.parent.elem.rename("div")

			image	:= (Image) src
			if (image.size != null) {
				style	:= ""
				sizes	:= image.size.split('x')
				width	:= sizes.getSafe(0)?.trimToNull?.toInt(10, false)
				height	:= sizes.getSafe(1)?.trimToNull?.toInt(10, false)
				
				// set size via style so it overrides any arbitrary CSS styles 
				if (width  != null)	style +=   "width:${width}px;"
				if (height != null)	style += " height:${height}px;"
				if (style.size > 0)
					html.parent?.elem?.set("style", style)
			}
	
			width	:= 16
			height	:= 9
			aspect	:= uri.query["aspectRatio"] 
			if (aspect != null) {
				assX 	:= aspect.split('x').getSafe(0)?.trimToNull?.toInt(10, false)
				assY	:= aspect.split('x').getSafe(1)?.trimToNull?.toInt(10, false)
				
				if (assX != null && assY != null) {
					width	= assX
					height	= assY
					
					// strip the query - then add it back; minus aspectRatio
					q  := uri.query.rw
					q.remove("aspectRatio")
					uri = uri[0..-2].plusName(uri.name).plusQuery(q)
				}
			}

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

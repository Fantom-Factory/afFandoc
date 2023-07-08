using fandoc::DocElem
using fandoc::Image

** https://vimeo.com/11712103
@Js
internal const class VimeoProcessor : ElemProcessor {
	
	override Obj? process(HtmlElem html, DocElem src) {
		if (html.name != "img") return null

		// re-write Vimeo share URLs - https://vimeo.com/11712103
		uri := html.getUri("src")
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
			
			// el-frame may be constrained in size by setting a max-width on .vimeoVideo
			html.parent?.elem?.addClass("vimeoVideo")

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

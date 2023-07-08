using fandoc::DocElem
using fandoc::Image

//	Video links:
//	https://caniuse.com/#search=webm
//	https://caniuse.com/#feat=mpeg4
//	https://stackoverflow.com/a/53258723/1532548	// autoplay loop muted playsinline
//	https://stackoverflow.com/questions/36081556/html-video-autoplay-loop
//	https://stackoverflow.com/questions/32430280/html5-video-fallback-when-all-types-unsupported
//	https://stackoverflow.com/questions/27785816/webm-before-or-after-mp4-in-html5-video-element

@Js
internal const class Html5VideoProcessor : ElemProcessor {
	
	const Str[] videoAttrs
	
	new make(Str? videoAttrs := null) {
		this.videoAttrs = (videoAttrs ?: "muted playsinline controls").split
	}
	
	override Obj? process(HtmlElem html, DocElem src) {
		if (html.name != "img") return null

		uri := html.getUri("src")
		if (uri == null) return null

		if (uri.isRel && uri.host == null && (uri.ext == "mp4" || uri.ext == "webm")) {
			
			// codecs are a little too complicated to use
			// https://developer.mozilla.org/en-US/docs/Web/Media/Formats/codecs_parameter
			type	:= "video/" + uri.ext

			// el-frame may be constrained in size by setting a max-width on .htmlVideo
			html.parent?.elem?.addClass("htmlVideo")

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
				
				HtmlElem("video").with {
					video := it
					videoAttrs.each { video[it] = "" }
					HtmlElem("source") {
						it["src"]			= uri
						it["type"]			= type
					},
					HtmlElem("p").addHtml("Your browser does not support HTML5 video. Here is a <a href=\"${uri.encode}\">link to the video</a> instead."),
				},
			}
		}
		
		return null
	}
}

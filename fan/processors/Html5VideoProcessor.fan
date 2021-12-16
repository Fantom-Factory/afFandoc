
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
	
	override Obj? process(HtmlElem elem) {
		if (elem.name != "img") return null

		uri := elem.getUri("src")
		if (uri == null) return null

		if (uri.isRel && uri.host == null && (uri.ext == "mp4" || uri.ext == "webm")) {
			
			// codecs are a little too complicated to use
			// https://developer.mozilla.org/en-US/docs/Web/Media/Formats/codecs_parameter
			type	:= "video/" + uri.ext
			
			// make sure the size is one that's recognised
			aspect	:= (elem["width"] ?: "") + "by" + (elem["height"] ?: "")
			if (!"21by9 16by9 4by3 1by1".split.contains(aspect))
				aspect = "16by9"
			
			// we always forget that <div> CANNOT be nested inside <p>
			if (elem.parent?.elem?.name == "p")
				elem.parent.elem.rename("div")

			return HtmlElem("div") {
				it.addClass("htmlVideo d-print-none embed-responsive embed-responsive-${aspect}")
				it["title"]				= elem["alt"]
				
				HtmlElem("video").with {
					video := it
					video.addClass("embed-responsive-item")
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

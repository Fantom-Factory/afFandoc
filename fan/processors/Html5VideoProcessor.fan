
@Js
internal const class Html5VideoProcessor : ElemProcessor {
	
	const Str[] videoAttrs
	
	new make(Str? videoAttrs := null) {
		this.videoAttrs = (videoAttrs ?: "muted playsinline controls").split
	}
	
	override Obj? process(HtmlElem elem) {
		if (elem.name != "img") return null

		uri := elem.getUri("src")
		if (uri.isRel && uri.host == null && (uri.ext == "mp4" || uri.ext == "webm")) {
			
			// codecs are a little too complicated to use
			// https://developer.mozilla.org/en-US/docs/Web/Media/Formats/codecs_parameter
			type	:= "video/" + uri.ext
			
			// make sure the size is one that's recognised
			aspect	:= (elem["width"] ?: "") + "by" + (elem["height"] ?: "")
			if (!"21by9 16by9 4by3 1by1".split.contains(aspect))
				aspect = "16by9"

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

using fandoc::DocElem

** An interface for processing '<pre>' text blocks.
@Js
mixin ElemProcessor {

	** Implement to process / alter / modify the given 'HtmlElem'.
	** Return a replacement 'Str' or 'HtmlElem'.
	abstract Obj? process(HtmlElem elem)
	
	** Creates a 'PreProcessor' from the given fn. 
	static new fromFn(|HtmlElem -> Obj?| fn) {
		FnElemProcessor(fn)
	}
	
	** A para processor that allows text to be prefixed with CSS class names and styles.
	static ElemProcessor cssPrefixProcessor() {
		CssPrefixProcessor()
	}
	
	** A link processor that opens external links in a new tab.
	static ElemProcessor externalLinkProcessor() {
		ExternalLinkProcessor()
	}
	
	** Adds the CSS class to the elem. Use for processing invalid links.
	static ElemProcessor invalidLinkProcessor(Str cssClass := "invalidLink") {
		fromFn |HtmlElem elem| { elem.addClass(cssClass) }
	}
	
	** Removes 'mailto:' hrefs and adds a 'data-unscramble' attribute.
	static ElemProcessor mailtoProcessor() {
		MailtoProcessor()
	}

	** An image processor that inlines (locally hosted) HTML 5 videos.
	** 'videoAttrs' defaults to 'muted playsinline controls'.
	static ElemProcessor html5VideoProcessor(Str? videoAttrs := null) {
		Html5VideoProcessor(videoAttrs)
	}	

	** An image processor that inlines Vimeo videos.
	static ElemProcessor vimeoProcessor() {
		VimeoProcessor()
	}
	
	** An image processor that inlines YouTube videos.
	static ElemProcessor youTubeProcessor() {
		YouTubeProcessor()
	}	
}

@Js
internal class FnElemProcessor : ElemProcessor {
	private  |HtmlElem -> Obj?| fn
	
	new make(|HtmlElem -> Obj?| fn) {
		this.fn = fn
	}
	
	override Obj? process(HtmlElem elem) {
		fn(elem)
	}
}

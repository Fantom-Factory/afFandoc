using fandoc::DocElem

** An interface for processing Fandoc elements.
@Js
mixin ElemProcessor {

	** Implement to process / alter / modify the given 'HtmlElem'.
	** Return a replacement 'Str' or 'HtmlElem'.
	abstract Obj? process(HtmlElem elem, DocElem src)
	
	** Creates a 'PreProcessor' from the given fn. 
	static new fromFn(|HtmlElem, DocElem -> Obj?| fn) {
		FnElemProcessor(fn)
	}

	** A link processor that allows URIs to be prefixed with CSS class names and styles.
	** Don't forget to *also* use the CssLinkResolver to avoid invalid links.
	static ElemProcessor cssLinkProcessor() {
		CssLinkProcessor()
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
	static ElemProcessor mailtoProcessor(Str attr := "data-unscramble") {
		MailtoProcessor(attr)
	}
	
	** Opens links to PDFs in a new tab.
	static ElemProcessor pdfLinkProcessor() {
		PdfLinkProcessor()
	}

	** An image processor that inlines (locally hosted) HTML 5 videos.
	** 'videoAttrs' defaults to 'muted playsinline controls'.
	static ElemProcessor html5VideoElProcessor(Str? videoAttrs := null) {
		Html5VideoProcessor(videoAttrs)
	}	

	** An image processor that inlines Vimeo videos.
	** Renders EveryLayout for Slim CSS classes.
	static ElemProcessor vimeoProcessor() {
		VimeoProcessor()
	}
	
	** An image processor that inlines YouTube videos.
	** Renders EveryLayout for Slim CSS classes.
	static ElemProcessor youTubeProcessor() {
		YouTubeProcessor()
	}	
}

@Js
internal class FnElemProcessor : ElemProcessor {
	private  |HtmlElem, DocElem -> Obj?| fn
	
	new make(|HtmlElem, DocElem -> Obj?| fn) {
		this.fn = fn
	}
	
	override Obj? process(HtmlElem elem, DocElem src) {
		fn(elem, src)
	}
}

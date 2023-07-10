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
	
	** Applies the given CSS prefix to the 'HtmlElem' - returns any unused text.
	static Str? applyCssPrefix(HtmlElem elem, Str cssStr) {
		CssPrefixProcessor.apply(elem, cssStr)
	}
	
	** A link processor that opens external links in a new tab.
	static ElemProcessor externalLinkProcessor() {
		ExternalLinkProcessor()
	}
	
	** A link processor that URLS with a scheme of 'javascript:' with a harmless '#' and sets a 'data-javascriptLink' attribute.  
	static ElemProcessor javascriptLinkProcessor() {
		javascriptLinkProcessor()
	}

	** Removes 'mailto:' hrefs and adds a 'data-mailto' attribute with the scrambled email address. 
	** 
	** Use 'uf.fromBase64(mailToAttr.reverse).readAllStr.reverse' to unscramble. 
	static ElemProcessor mailtoProcessor(Str attr := "data-mailto") {
		MailtoProcessor(attr)
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

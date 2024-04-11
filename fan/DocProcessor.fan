using fandoc::DocElem

** An interface for processing Documents after rendering.
@Js
mixin DocProcessor {

	** Implement to inspect the final HTML, and optionally return a replacement 'Str'. 
	abstract Obj? process(HtmlElem? elem, DocElem src, Str html)
	
	** Creates a 'DocProcessor' from the given fn. 
	static new fromFn(|HtmlElem?, DocElem, Str -> Obj?| fn) {
		DocProcessorFn(fn)
	}	
}

@Js
internal class DocProcessorFn : DocProcessor {
	private  |HtmlElem?, DocElem, Str -> Obj?| fn
	
	new make(|HtmlElem?, DocElem, Str -> Obj?| fn) {
		this.fn = fn
	}
	
	override Obj? process(HtmlElem? elem, DocElem src, Str html) {
		fn(elem, src, html)
	}
}
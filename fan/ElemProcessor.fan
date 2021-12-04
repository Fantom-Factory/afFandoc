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

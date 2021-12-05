
** An interface for processing '<pre>' text blocks.
@Js
mixin PreProcessor {

	** Implement to process the given 'pre' text to the given 'out'. 
	abstract Obj? process(HtmlElem elem, Uri cmd, Str text)
	
	** Creates a 'PreProcessor' from the given fn. 
	static new fromFn(|HtmlElem, Uri, Str| fn) {
		PreProcessorFn(fn)
	}
	
	** Adds the pre-text as raw HTML.
	static PreProcessor htmlProcessor() {
		fromFn |HtmlElem elem, Uri uri, Str html| { elem.addHtml(html) }	
	}
	
	** Standard Syntax pretty printing.
	static PreProcessor syntaxProcessor() {
		SyntaxPreProcessor()
	}
	
	** Standard table printing.
	static PreProcessor tableProcessor() {
		TablePreProcessor()
	}
}

@Js
internal class PreProcessorFn : PreProcessor {
	private  |HtmlElem, Uri, Str -> Obj?| fn
	
	new make(|HtmlElem, Uri, Str -> Obj?| fn) {
		this.fn = fn
	}
	
	override Obj? process(HtmlElem elem, Uri cmd, Str text) {
		fn(elem, cmd, text)
	}
}

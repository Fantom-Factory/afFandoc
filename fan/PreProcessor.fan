using fandoc::DocElem

** An interface for processing '<pre>' text blocks.
@Js
mixin PreProcessor {

	** Implement to process the given 'pre' text, and optionally return a replacement 'HtmlElem' or 'Str'. 
	abstract Obj? process(HtmlElem elem, DocElem src, Uri cmd, Str text)
	
	** Creates a 'PreProcessor' from the given fn. 
	static new fromFn(|HtmlElem, Uri, Str -> Obj?| fn) {
		PreProcessorFn(fn)
	}

	** Adds the pre-text as raw HTML.
	static PreProcessor htmlProcessor() {
		fromFn |HtmlElem elem, Uri uri, Str html -> HtmlNode| { HtmlText(html, true) }	
	}
	
	** Standard Syntax pretty printing.
	static SyntaxProcessor syntaxProcessor([Str:Str]? aliases) {
		SyntaxProcessor(aliases)
	}
	
	** Standard table printing.
	static TableProcessor tableProcessor(|Str->Str|? toHtmlFn := null) {
		TableProcessor(toHtmlFn)
	}
	
	** Create HTML block elements.
	static PreProcessor divProcessor(|Str->Str|? toHtmlFn := null) {
		DivProcessor(toHtmlFn)
	}
}

@Js
internal class PreProcessorFn : PreProcessor {
	private  |HtmlElem, Uri, Str -> Obj?| fn
	
	new make(|HtmlElem, Uri, Str -> Obj?| fn) {
		this.fn = fn
	}
	
	override Obj? process(HtmlElem elem, DocElem src, Uri cmd, Str text) {
		fn(elem, cmd, text)
	}
}

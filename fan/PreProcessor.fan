using fandoc::DocElem

** An interface for processing '<pre>' text blocks.
@Js
mixin PreProcessor {

	** Implement to process the given 'pre' text to the given 'out'. 
	abstract Void process(OutStream out, DocElem elem, Uri cmd, Str preText)
	
	** Creates a 'PreProcessor' from the given fn. 
	static new fromFn(|OutStream, DocElem, Uri, Str| fn) {
		PreProcessorFn(fn)
	}
}

@Js
internal class PreProcessorFn : PreProcessor {
	private |OutStream, DocElem, Uri, Str| fn
	
	new make(|OutStream, DocElem, Uri, Str| fn) {
		this.fn = fn
	}
	
	override Void process(OutStream out, DocElem elem, Uri cmd, Str preText) {
		fn(out, elem, cmd, preText)
	}
}

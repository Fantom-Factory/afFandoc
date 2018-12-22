using fandoc::DocElem

** An interface for processing '<pre>' text blocks.
@Js
mixin PreProcessor {

	** Implement to process the given 'pre' text to the given 'out'. 
	abstract Void process(OutStream out, DocElem elem, Uri cmd, Str preText)
}

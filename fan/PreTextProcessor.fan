using fandoc::DocElem

mixin PreTextProcessor {
	abstract Void process(OutStream out, DocElem elem, Uri cmd, Str preText)
}

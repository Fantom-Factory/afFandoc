using fandoc::Doc
using fandoc::DocElem
using fandoc::DocNode
using fandoc::DocText
using fandoc::DocWriter
using fandoc::FandocParser

** An intelligent DocWriter that has context.
@Js
abstract class DocWriter2 {
	
	Str writeToStr(DocElem elem) {
		impl := DocWriterImpl(this)
		if (elem is Doc)
			impl.docStart(elem)
		elem.write(impl)
		if (elem is Doc)
			impl.docEnd(elem)
		return impl.output
	}

	Str parseAndWriteToStr(Str fandoc) {
		// auto-detect headers - no legal fandoc should start with ***** unless it's a header!
		doc := FandocParser() { it.parseHeader = fandoc.trimStart.startsWith("*****") }.parseStr(fandoc)
		return writeToStr(doc)
	}
	
	abstract Void render(OutStream out, DocElem elem, Str innerText)

	virtual Str escapeText(DocElem elem, Str text) { text }
}

@Js
internal class DocWriterImpl : DocWriter {
	internal Str?				output
	private  DocWriterNode[]	elemStack	:= DocWriterNode[,]
	private  DocWriter2			docWriter2
	
	new make(DocWriter2 docWriter2) {
		this.docWriter2 = docWriter2
	}
	
	@NoDoc
	override Void docStart(Doc doc) { }
	
	@NoDoc
	override Void docEnd(Doc doc) { }
	
	@NoDoc
	override Void elemStart(DocElem elem) {
		elemStack.push(DocWriterNode {
			it.elem = elem
		})
	}

	@NoDoc
	override Void elemEnd(DocElem elem) {
		pop := elemStack.pop
		if (pop.elem !== elem)
			throw Err("Unequal DocElems $pop.elem !== elem")
		
		out := elemStack.peek?.out
		
		if (out == null)
			output = pop.buf.toStr
		else
			docWriter2.render(out, elem, pop.buf.toStr)
	}

	@NoDoc
	override Void text(DocText docText) {
		node := elemStack.peek
		node.out.print(docWriter2.escapeText(node.elem, docText.str))
	}	
}

@Js
internal class DocWriterNode {
	DocElem		elem
	StrBuf		buf		:= StrBuf()
	OutStream	out		:= buf.out
	
	new make(|This| f) { f(this) }
}

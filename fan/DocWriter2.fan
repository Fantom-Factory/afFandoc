using fandoc::Doc
using fandoc::DocElem
using fandoc::DocNode
using fandoc::DocText
using fandoc::DocWriter
using fandoc::FandocParser

** An intelligent DocWriter that has context.
abstract class DocWriter2 : DocWriter {

	private Str?			output
	private DocWriterNode[]	elemStack	:= DocWriterNode[,]
	
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
			render(out, elem, pop.buf.toStr)
	}

	@NoDoc
	override Void text(DocText docText) {
		node := elemStack.peek
		node.out.print(escapeText(node.elem, docText.str))
	}
	
	Str writeToStr(DocNode node) {
		node.write(this)
		return output
	}
	
	Str parseAndWriteToStr(Str fandoc) {
		doc := FandocParser() { it.parseHeader = false }.parseStr(fandoc)
		return writeToStr(doc)
	}
	
	abstract Void render(OutStream out, DocElem elem, Str innerText)

	virtual Str escapeText(DocElem elem, Str text) { text }
	
	Str result() { output }
}

internal class DocWriterNode {
	DocElem		elem
	StrBuf		buf		:= StrBuf()
	OutStream	out		:= buf.out
	
	new make(|This| f) { f(this) }
}

using fandoc::DocElem

** div: .class.{style} Use for blocks
@Js
internal class DivProcessor : PreProcessor { 
	private HtmlDocWriter docWriter

	new make(HtmlDocWriter docWriter) {
		this.docWriter = docWriter
	}
	
	@NoDoc
	override Obj? process(HtmlElem elem, DocElem src, Uri cmd, Str preText) {
		div := HtmlElem("div").addText(cmd.pathStr.trimStart)
		CssPrefixProcessor().process(div, src)
		div.removeAllChildren
		
		inner := docWriter.parseAndWriteToStr(preText, "div:")
		div.addHtml(inner.trimEnd)
		return div
	}
}

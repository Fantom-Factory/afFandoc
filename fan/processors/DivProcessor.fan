using fandoc::DocElem

** div: .class.{style} Use for blocks
@Js
internal class DivProcessor : PreProcessor { 
	** Hook for rendering cell text. Just returns 'text.toXml' by default.
	|Str->Str|?	renderHtmlFn

	new make(|Str->Str|? renderHtmlFn := null) {
		this.renderHtmlFn = renderHtmlFn
	}
	
	@NoDoc
	override Obj? process(HtmlElem elem, DocElem src, Uri cmd, Str preText) {
		div		:= HtmlElem("div")
		inner	:= renderHtmlFn(preText)
		div.addHtml(inner.trimEnd)
		
		CssPrefixProcessor.apply(div, cmd.pathStr)
		
		return div
	}
}

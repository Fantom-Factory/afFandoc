
@Js
internal class CssPrefixProcessor : ElemProcessor {
	
	override Obj? process(HtmlElem elem) {
		node := elem.nodes.first as HtmlText
		if (node == null || node.isHtml)
			return null
		
		body := node.text
		more := true
		
		while (body.size > 2 && more) {
			more = false
			// I've purposely NOT supported #IDs - it just seems... wrong!
			
			// escape '.cssClass' with '\.cssClass'
			if (body[0] == '\\' && body[1] == '.') {
				body = body[1..-1]
				node.text = body
			} else

			// use simple class styling:  ".callout.glitch Hello!"
			if (body[0] == '.' && body[1].isLower) {
				i := body.chars.findIndex |c, i| { i > 2 && !c.isAlphaNum && c != '-' && c != '_' } ?: body.size-1
//				i := body.index("." , 2) ?: body.size-1
//				j := body.index(" " , 2) ?: body.size-1
//				k := body.index("\t", 2) ?: body.size-1
//				i  = i.min(j).min(k)
				css  := i == body.size-1 ? body[1  .. i] : body[1..<i]
				body  = i == body.size-1 ? body[i+1..-1] : body[i..-1]
				body  = body.trimStart
				elem.addClass(css.trimEnd)
				node.text = body
				more = true
			} else

			// use curly bracket for embedded HTML styling:  ".{background-color: pink; padding 1rem; }"
			if (body[0] == '.' && body[1] == '{') {
				i := body.index("}" ) ?: body.size-1
				style := body[2..<i]
				body   = body[i+1..-1].trimStart
				
				elem["style"] = style.trim
				node.text = body
				more = true
			}	
		}
		
		return null
	}
}

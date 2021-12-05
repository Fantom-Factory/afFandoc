
@Js
internal class CssPrefixProcessor : ElemProcessor {
	
	override Obj? process(HtmlElem elem) {
		body := elem.text
		more := true
		
		while (body.size > 3 && more) {
			more = false
			// I've purposely NOT supported #IDs - it seems wrong!
			
			// escape '.cssClass' with '\.cssClass'
			if (body[0] == '\\' && body[1] == '.') {
				body = body[1..-1]
				elem.text = body
			} else

			// use simple class styling:  ".callout.glitch Hello!"
			if (body[0] == '.' && body[1].isLower) {
				i := body.index("." , 2) ?: body.size-1
				j := body.index(" " , 2) ?: body.size-1
				k := body.index("\t", 2) ?: body.size-1
				i  = i.min(j).min(k)
				css  := body[1..<i]
				body  = body[i+1..-1].trimStart
				elem.addClass(css)
				elem.text = body
				more = true
			} else

			// use curly bracket for embedded HTML styling:  ".{background-color: pink; padding 1rem; }"
			if (body[0] == '.' && body[1] == '{') {
				i := body.index("}" ) ?: body.size-1
				style := body[2..<i]
				body   = body[i+1..-1].trimStart
				
				elem["style"] = style.trim
				elem.text = body
				more = true
			}	
		}
		
		return null
	}
}

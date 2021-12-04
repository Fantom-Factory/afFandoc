
@Js
internal class CssPrefixProcessor : ElemProcessor {
	
	override Obj? process(HtmlElem elem) {
		body := elem.text
		
		while (body.size > 3) {
			// I've purposely NOT supported #IDs - it seems wrong!
			
			// escape '.cssClass' with '\.cssClass'
			if (body[0] == '\\' && body[1] == '.')
				body = body[1..-1]
			else

			// use simple class styling:  ".callout.glitch Hello!"
			if (body[0] == '.' && body[1].isLower) {
				i := body.index("." ) ?: body.size-1
				j := body.index(" " ) ?: body.size-1
				k := body.index("\t") ?: body.size-1
				i  = i.min(j).min(k)
				css  := body[1..<i]
				body  = body[i+1..-1].trimStart
				elem.addClass(css)
			} else

			// use curly bracket for embedded HTML styling:  ".{background-color: pink; padding 1rem; }"
			if (body[0] == '.' && body[1] == '{') {
				i := body.index("}" ) ?: body.size-1
				style := body[2..<i]
				body   = body[i+1..-1].trimStart
				
				elem["style"] = style.trim
			}	
		}
		
		return null
	}
}

using fandoc::DocElem

@Js
internal class CssPrefixProcessor : ElemProcessor {
	
	override Obj? process(HtmlElem elem, DocElem src) {
		node := elem.nodes.first as HtmlText
		if (node == null || node.isHtml)
			return null
		
		body := node.text
		data := parseStying(body)
		
		if (data["text"] != body)
			node.text = data["text"]
		
		if (data["class"] != null)
			data["class"].split.each { elem.addClass(it) }
		
		if (data["style"] != null)
			elem["style"] = data["style"]

		return null
	}
	
	static Str:Str? parseStying(Str text) {
		clas := Str[,]
		styl := Str[,]
		more := true
		while (text.size > 2 && more) {
			more = false
			// I've purposely NOT supported #IDs - it just seems... wrong!
			
			// escape '.cssClass' with '\.cssClass'
			if (text[0] == '\\' && text[1] == '.') {
				text = text[1..-1]
			} else

			// use simple class styling:  ".callout.glitch Hello!"
			if (text[0] == '.' && text[1].isLower) {
				i := text.chars.findIndex |c, i| { i > 2 && !c.isAlphaNum && c != '-' && c != '_' } ?: text.size-1
//				i := text.index("." , 2) ?: text.size-1
//				j := text.index(" " , 2) ?: text.size-1
//				k := text.index("\t", 2) ?: text.size-1
//				i  = i.min(j).min(k)
				css  := i == text.size-1 ? text[1  .. i] : text[1..<i]
				text  = i == text.size-1 ? text[i+1..-1] : text[i..-1]
				text  = text.trimStart
				clas.add(css.trimEnd)
				more = true
			} else

			// use curly bracket for embedded HTML styling:  ".{background-color: pink; padding 1rem; }"
			if (text[0] == '.' && text[1] == '{') {
				i := text.index("}" ) ?: text.size-1
				style := text[2..<i]
				text   = text[i+1..-1].trimStart
				
				styl.add(style.trim)
				more = true
			}	
		}

		return Str:Str?[
			"text"	: text,
			"class"	: clas.join(" " ).trimToNull,
			"style"	: styl.join("; ").trimToNull,
		] 
	}
}

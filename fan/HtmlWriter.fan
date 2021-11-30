using fandoc::Doc
using fandoc::DocElem
using fandoc::DocText
using fandoc::DocNodeId
using fandoc::DocWriter

class HtmlWriter2 : DocWriter { 
	Str:PreProcessor	preProcessors		:= Str:PreProcessor[:]
	LinkResolver[]		linkResolvers		:= LinkResolver[,]
	@NoDoc Str			invalidLinkClass	:= "invalidLink"
	StrBuf				str					:= StrBuf()
	HtmlNode?			htmlNode

	@NoDoc
	override Void docStart(Doc doc) { }
	
	@NoDoc
	override Void docEnd(Doc doc) { }
	
	@NoDoc
	override Void elemStart(DocElem elem) {
		cur := toHtmlNode()
		htmlNode?.add(cur)
		htmlNode = cur
	}

	@NoDoc
	override Void elemEnd(DocElem elem) {
		if (htmlNode == null) return

		cur := htmlNode
		par := htmlNode?.parent
		
		if (cur != null && elem.id == DocNodeId.pre) {
			body	:= cur.elem.text
			idx		:= body.index("\n") ?: -1
			cmdTxt	:= body[0..idx].trim
			cmd 	:= Uri(cmdTxt, false)		

			if (cmd?.scheme != null && preProcessors.containsKey(cmd.scheme)) {
				str		:= StrBuf()
				preText := body[idx..-1]
				preProcessors[cmd.scheme].process(str.out, elem, cmd, preText)
				cur = cur.replaceWith(HtmlText(str.toStr))
			}
		}
		
		if (cur != null && par == null)
			cur.print(str.out)
		
		htmlNode = par
	}

	@NoDoc
	override Void text(DocText docText) {
		htmlNode = HtmlText(docText.str)
	}	
	
	Str toHtml() { str.toStr }
	
	// ----

	virtual HtmlNode toHtmlNode() {
		throw Err()
	}
}

@NoDoc
abstract class HtmlNode {
	private	HtmlNode?	_parent
	private HtmlNode[]	_nodes	:= HtmlNode[,]
//			Str:Obj?	meta	:= Str:Obj?[:]

	HtmlNode?	parent()	{ _parent }
	HtmlNode[]	nodes()		{ _nodes.ro }
	HtmlElem?	elem()		{ this is HtmlElem ? this : parent?.elem }
	virtual Str	text()		{ _nodes.join("") { it.text } }
	
	@Operator
	This add(HtmlNode node) {
		this.nodes.add(node)
		node._parent = this
		return this
	}
	
	HtmlNode replaceWith(HtmlNode node) {
		i := this._parent?._nodes?.indexSame(this)
			 this._parent?._nodes?.set(i, node)
		return node
	}
	
	abstract internal Void print(OutStream out)
	
	@NoDoc
	override Str toStr() { str := StrBuf(); print(str.out); return str.toStr }
}

@NoDoc
class HtmlElem : HtmlNode {
	static const Str[] voidTags := "area base br col embed hr img input keygen link menuitem meta param source track wbr".split
	static const Str[] rawTags	:= "script style textarea title".split

	const	Str			name
	private Str:Obj? 	attrs	:= Str:Obj?[:] { ordered = true}
	
	new make(Str name) {
		this.name = name.lower.trim
	}

	** Gets an attribue value
	@Operator
	Str? get(Str attr) {
		attrs[attr]
	}

	** Sets an attribute value
	@Operator
	HtmlElem set(Str attr, Str val) {
		attrs[attr] = val
		return this
	}
	
	** Returns 'true' if this is a 'Void' element.
	** See [Void elements]`https://html.spec.whatwg.org/multipage/syntax.html#void-elements`.
	Bool isVoid() {
		voidTags.contains(name)
	}
	
	** Returns 'true' if this is a 'Raw Text' element.
	** See [Raw text elements]`https://html.spec.whatwg.org/multipage/syntax.html#raw-text-elements`.
	Bool isRawText() {
		rawTags.contains(name)
	}
	
	@NoDoc
	override internal Void print(OutStream out) {
		if (isVoid && nodes.size > 0)
			typeof.pod.log.warn("Void tag '${name}' *MUST NOT* have content!") 

		mod := OutStream.xmlEscNewlines + OutStream.xmlEscQuotes
		out.writeChar('<').writeXml(name, mod)
		if (attrs.size > 0) {
			attrKeys := attrs.keys
			for (i := 0; i < attrKeys.size; ++i) {
				key := attrKeys[i]
				val := attrs[key]
				out.writeChar(' ').writeXml(key, mod)
				
				if (val is Uri)
					val = ((Uri) val).encode
				if (val != null)
					out.writeChar('=').writeChar('"').writeXml(val.toStr, mod).writeChar('"')
			}
		}
		
		if (nodes.isEmpty && isVoid == false)
			out.writeChar('/')
		if (nodes.isEmpty)
			out.writeChar('>')
		
		if (nodes.size > 0) {
			for (i := 0; i < nodes.size; ++i) {
				node := nodes[i]
				node.print(out)
			}
			out.writeChar('<').writeChar('/').writeXml(name, mod).writeChar('>')
		}
	}
}


@NoDoc
class HtmlText : HtmlNode {
	override	Str		text
				Bool	raw
	
	new make(Str text, Bool raw := false) {
		this.text = text
	}

	@NoDoc
	override Void print(OutStream out) {
		if (raw) out.writeChars(text); else out.writeXml(text)
	}
}

//@NoDoc
//class HtmlConditional : HtmlNode {
//	Str? condition
//	private HtmlNode[] nodes := [,]
//	
//	new make(|This| f) { f(this) }
//
//	new makeWithCondition(Str? condition, |This|? in := null) {
//		this.condition = condition.trim
//		in?.call(this)
//	}
//
//	@Operator
//	This add(HtmlNode node) {
//		nodes.add(node)
//		return this
//	}
//
//	internal HtmlElem? content() {
//		return (nodes.size == 1 && nodes.first is HtmlElem) ? nodes.first : null
//	}
//	
//	@NoDoc
//	override internal Void print(OutStream out) {
//		str := Str.defVal
//		
//		if (condition != null)
//			str += "<!--[${condition.toXml}]>"
//		
//		str += nodes.join(Str.defVal) { it.print().trim }
//		
//		if (condition != null)
//			str += "<![endif]-->"
//
//		return str
//	}
//}
//
//@NoDoc
//class HtmlComment : HtmlNode {
//	private Str comment
//	
//	new make(Str comment) {
//		this.comment = comment
//	}
//
//	@NoDoc
//	override internal Void print(OutStream out) {
//		return "<!-- ${comment.toXml} -->"
//	}
//}


@Js
abstract class HtmlNode {
	private	HtmlNode?	_parent
	private HtmlNode[]	_nodes	:= HtmlNode[,]
//			Str:Obj?	meta	:= Str:Obj?[:]

	HtmlNode?	parent()	{ _parent }
	HtmlNode[]	nodes()		{ _nodes }
	HtmlElem?	elem()		{ this as HtmlElem }
	
	@Operator
	This add(HtmlNode node) {
		if (node._parent != null)
			throw Err("HtmlNode already parented: ${node}")
		this._nodes.add(node)
		node._parent = this
		return this
	}
	
	This addAll(HtmlNode[] nodes) {
		nodes.each { this.add(it) }
		return this
	}
	
	HtmlNode replaceWith(HtmlNode node) {
		i := this._parent?._nodes?.indexSame(this)
			 this._parent?._nodes?.set(i, node)
		return node
	}
	
	This removeMe() {
		this._parent?._nodes?.removeSame(this)
		this._parent = null
		return this
	}
	
	This removeAllChildren() {
		_nodes.each { it._parent = null }
		_nodes.clear
		return this
	}
	
	abstract Void print(OutStream out)
	
	@NoDoc
	override Str toStr() { str := StrBuf(); print(str.out); return str.toStr }
}


@Js
class HtmlElem : HtmlNode {
	static const Str[] voidTags := "area base br col embed hr img input keygen link menuitem meta param source track wbr".split
	static const Str[] rawTags	:= "script style textarea title".split

	private	Str			_name
	private Str:Str? 	attrs	:= Str:Str?[:] { ordered = true}
	
	Str? id {
		get { this["id"] }
		set { this["id"] = it }
	}	

	Str? klass {
		get { this["class"] }
		set { this["class"] = it }
	}

	Str? title {
		get { this["title"] }
		set { this["title"] = it }
	}
	
	Str	text {
		get {
			if (nodes.size == 1 && nodes.first is HtmlText)
				return ((HtmlText) nodes.first).getPlainText

			text := ""
			nodes.each |node| {
				if (node is HtmlElem)
					text += ((HtmlElem) node).text
				if (node is HtmlText) {
					text += ((HtmlText) node).getPlainText
				}
			}
			return text
		}
		set {
			nodes.clear
			nodes.add(HtmlText(it))
		}
	}
	
	new make(Str name, Str? cssClass := null) {
		this._name = name.lower.trim
		if (cssClass != null)
			addClass(cssClass)
	}
	
	Str name() { _name }
	
	This rename(Str newName) {
		_name = newName
		return this
	}

	** Gets an attribue value
	@Operator
	Str? get(Str attr) {
		attrs[attr]
	}

	** Sets an attribute value. Empty strings for name only attrs.
	@Operator
	HtmlElem set(Str attr, Obj? val) {
		if (val is Uri)
			val = ((Uri) val).encode
		attrs[attr] = val

		if (val == "")
			attrs[attr] = null
		// I know null should really indicate a name-only attr,
		// but that messes with my nice getters / setters for id / class
		// and *could* also be un-expected behaviour
		if (val == null)
			attrs.remove(attr)
		return this
	}
	
	Uri? getUri(Str attr) {
		val := attrs[attr]
		return val == null ? null : Uri.decode(val, false)
	}
	
	This addClass(Str cssClass) {
		if (cssClass.isEmpty) return this
		klass = (klass?.plus(" ") ?: "") + cssClass
		return this
	}
	
	This removeClass(Str cssClass) {
		if (klass == null || cssClass.isEmpty) return this
		klass = klass.split.removeAll(cssClass.split).join(" ")
		return this
	}
	
	This addText(Str text) {
		add(HtmlText(text))
	}
	
	This addHtml(Str text) {
		add(HtmlText(text, true))
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
	override Void print(OutStream out) {
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
				if (val != null)
					out.writeChar('=').writeChar('"').writeXml(val.toStr, mod).writeChar('"')
			}
		}
		out.writeChar('>')
		
		for (i := 0; i < nodes.size; ++i) {
			node := nodes[i]
			node.print(out)
		}

		// interestingly, HTML does NOT allow self-closing tags (that's just XML)
		// instead it just lets Void tags omit their end tag
		if (isVoid == false || nodes.size > 0)
			out.writeChar('<').writeChar('/').writeXml(name, mod).writeChar('>')
	}
}


@Js
class HtmlText : HtmlNode {
	Str		text
	Bool	isHtml
	
	new make(Str text, Bool isHtml := false) {
		this.text	= text
		this.isHtml	= isHtml
	}
	
	Str getPlainText() {
		isHtml ? "" : text
	}

	@NoDoc
	override Void print(OutStream out) {
		if (text.isEmpty) return
		if (isHtml || parent?.elem?.isRawText == true) out.writeChars(text); else out.writeXml(text)
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

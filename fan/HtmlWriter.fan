using fandoc::Doc
using fandoc::DocElem
using fandoc::DocText
using fandoc::DocNodeId
using fandoc::DocWriter
using fandoc

@Js
class HtmlWriter2 : DocWriter { 
	DocNodeId:Str		cssClasses			:= DocNodeId:Str[:] { it.def = "" }
	Str:ElemProcessor	preProcessors		:= Str:ElemProcessor[:]
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
		cur := toHtmlNode(elem)
		htmlNode?.add(cur)
		htmlNode = cur
	}

	@NoDoc
	override Void elemEnd(DocElem elem) {
		if (htmlNode == null) return

		cur := htmlNode
		par := htmlNode?.parent
		res := null as Obj

		switch (elem.id) {
			case DocNodeId.para		: res = processPara(cur)
			case DocNodeId.pre		: res = processPre(cur)
			case DocNodeId.link		: res = processLink(cur)
			case DocNodeId.image	: res = processImage(cur)
		}
		
		if (res != null && res != cur) {
			if (res is Str)
				res = HtmlText(res)
			if (res isnot HtmlNode)
				throw UnsupportedErr("Unknown HtmlNode: ${res.typeof}")
			cur = cur.replaceWith(res)
		}
		
		if (par == null)
			cur.print(str.out)
		
		htmlNode = par
	}

	@NoDoc
	override Void text(DocText docText) {
		htmlNode = HtmlText(docText.str)
	}	
	
	Str toHtml() { str.toStr }
	
	// ----
	
	virtual Obj? processPara(HtmlElem elem) {
		// TODO - enableParaStlying
		// para text to start with #id  - escape with \#not id
		// para text to start with .css -  \.not css
		// para text to start with .{style:here} - 
		
		elem
	}

	virtual Obj? processPre(HtmlElem elem) {
		body	:= elem.text
		idx		:= body.index("\n") ?: -1
		cmdTxt	:= body[0..idx].trim
		cmd 	:= Uri(cmdTxt, false)		

		if (cmd?.scheme != null && preProcessors.containsKey(cmd.scheme)) {
			str		:= StrBuf()
			preText := body[idx..-1]
			replace	:= preProcessors[cmd.scheme].process(elem)
			return replace
		}
		return elem
	}

	virtual Obj? processLink(HtmlElem elem) {
		// ![YouTube vids][16x9]`https://www.youtube.com/embed/2SURpUQzUsE`
		elem
	}

	virtual Obj? processImage(HtmlElem elem) {
		elem
	}

	virtual HtmlNode toHtmlNode(DocElem elem) {
		html := HtmlElem(elem.htmlName)
		
		html.id = elem.anchorId
		
		switch (elem.id) {
			case DocNodeId.para:
				para := (Para) elem
				if (para.admonition != null) {
					admon := para.admonition.all { it.isUpper } ? para.admonition.lower : para.admonition
					html.addClass(admon)
				}

			case DocNodeId.heading:
				heading := (Heading) elem
				if (heading.anchorId == null)
					html.id = toId(heading.title)

			case DocNodeId.image:
				image := (Image) elem
				html["src"] = resolveLink(elem, image.uri) ?: image.uri
				html["alt"] = image.alt
				if (image.size != null) {
					sizes := image.size.split('x')
					html["width"]	= sizes.getSafe(0)?.trimToNull
					html["height"]	= sizes.getSafe(1)?.trimToNull
				}

			case DocNodeId.link:
				link := (Link) elem
				url  := Uri(link.uri, false)
				uri := resolveLink(link, link.uri)
				html["href"] = uri ?: link.uri
		
				if (uri == null)
					html.addClass(invalidLinkClass)
	
			case DocNodeId.orderedList:
				ol := (OrderedList) elem
				html["style"] = "list-style-type: " + ol.style.htmlType
		}
		
		html.addClass(cssClasses[elem.id] ?: "")
		return html
	}
	
	** Calls the 'LinkResolvers' looking for valid links.
	virtual Uri? resolveLink(DocElem elem, Str url) {
		uri := Uri(url, false)
		if (uri == null) return null
		scheme	:= uri.scheme == null ? null : url[0..<uri.scheme.size]
		link	:= linkResolvers.eachWhile { it.resolve(elem, scheme, uri) }
		return link
	}


	** Special end-tag handling for Void Elements.
	** See [Void Elements]`https://www.w3.org/TR/html5/syntax.html#void-elements` in the W3C HTML5 specification.
	virtual Bool isVoidElem(DocElem elem) {
		elem.id == DocNodeId.image ||
		elem.id == DocNodeId.hr
	}
	
	** Writes out an HTML attribute.
	** If 'val' is 'null' a [HTML5 Boolean attribute]`http://w3c.github.io/html/infrastructure.html#sec-boolean-attributes` is written out.
	** If 'val' is a 'Uri' then it's [encoded form]`sys::Uri.encode` is written out.
	** Else 'val.toStr' is used.
	** 
	** All attribute values are XML escaped. 
	virtual Void attr(OutStream out, Str key, Obj? val) {
		if (val == null) {
			out.writeChar(' ').print(key)
			return
		}
		val = val is Uri ? ((Uri) val).encode : val
		out.writeChar(' ').print(key).writeChar('=').writeChar('"')
		val.toStr.each |Int ch| {
			if 		(ch == '<')	 out.print("&lt;")
			else if (ch == '&')	 out.print("&amp;")
			else if (ch == '\'') out.print("&#39;")
			else if (ch == '"')	 out.print("&#34;")
			else				 out.writeChar(ch)
		}
		out.writeChar('"')
	}
	
	private static Str toId(Str humanName) {
		Str.fromChars(humanName.fromDisplayName.chars.findAll { it.isAlphaNum })
	}
}

@Js
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


@Js
class HtmlElem : HtmlNode {
	static const Str[] voidTags := "area base br col embed hr img input keygen link menuitem meta param source track wbr".split
	static const Str[] rawTags	:= "script style textarea title".split

	const	Str			name
	private Str:Obj? 	attrs	:= Str:Obj?[:] { ordered = true}
	
	Str? id {
		get { this["id"] }
		set { this["id"] = it }
	}	

	Str? klass {
		get { this["class"] }
		set { this["class"] = it }
	}
	
	new make(Str name) {
		this.name = name.lower.trim
	}

	** Gets an attribue value
	@Operator
	Str? get(Str attr) {
		attrs[attr]
	}

	** Sets an attribute value. Empty strings for name only attrs.
	@Operator
	HtmlElem set(Str attr, Obj? val) {
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


@Js
class HtmlText : HtmlNode {
	override	Str		text
				Bool	raw
	
	new make(Str text, Bool raw := false) {
		this.text = text
	}

	@NoDoc
	override Void print(OutStream out) {
		if (raw || elem.isRawText) out.writeChars(text); else out.writeXml(text)
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

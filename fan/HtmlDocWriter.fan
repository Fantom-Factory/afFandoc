using fandoc::Doc
using fandoc::DocElem
using fandoc::DocText
using fandoc::DocNodeId
using fandoc::DocWriter
using fandoc::Para
using fandoc::Heading
using fandoc::Image
using fandoc::Link
using fandoc::OrderedList
using fandoc::FandocParser
//using fandoc

@Js
class HtmlDocWriter : DocWriter { 
	DocNodeId:Str		cssClasses			:= DocNodeId:Str[:] { it.def = "" }
	LinkResolver[]		linkResolvers		:= LinkResolver[,]
	ElemProcessor[]		linkProcessors		:= ElemProcessor[,]
	ElemProcessor[]		imageProcessors		:= ElemProcessor[,]
	ElemProcessor[]		paraProcessors		:= ElemProcessor[,]
	Str:PreProcessor	preProcessors		:= Str:PreProcessor[:]
	@NoDoc Str			invalidLinkClass	:= "invalidLink"
	StrBuf				str					:= StrBuf()
	HtmlNode?			htmlNode

	** A simple HTML writer that mimics the original; no invalid links and no pre-block-processing.
	static HtmlDocWriter original() {
		HtmlDocWriter {
			it.linkResolvers = [
				LinkResolver.passThroughResolver,
			]
		}
	}
	
	** A HTML writer that performs pre-block-processing for tables and syntax colouring.
	static HtmlDocWriter fullyLoaded() {
		HtmlDocWriter {
			it.linkResolvers = [
				LinkResolver.schemePassThroughResolver,
				LinkResolver.pathAbsPassThroughResolver,
				LinkResolver.idPassThroughResolver,
				FandocLinkResolver(),
				LinkResolver.javascriptErrorResolver,
				LinkResolver.passThroughResolver,
			]
			it.paraProcessors = [
				ElemProcessor.cssPrefixProcessor,
			]
			it.imageProcessors	= [
				VimeoImageProcessor(),
				YouTubeImageProcessor(),
			]
			it.preProcessors["table"] = TablePreProcessor()
			if (Env.cur.runtime != "js")
				it.preProcessors["syntax"] = SyntaxPreProcessor()
		}
	}
	
	** Writes the given elem to a string.
	Str writeToStr(DocElem elem) {
		str.clear
		elem.write(this)
		return str.toStr
	}

	** Writes the given fandoc to a string.
	** Header properties are auto-dectected.
	Str parseAndWriteToStr(Str fandoc) {
		// auto-detect headers - no legal fandoc should start with ***** unless it's a header!
		doc := FandocParser() { it.parseHeader = fandoc.trimStart.startsWith("*****") }.parseStr(fandoc)
		return writeToStr(doc)
	}
	
	@NoDoc
	override Void docStart(Doc doc) { }
	
	@NoDoc
	override Void docEnd(Doc doc) { }
	
	@NoDoc
	override Void elemStart(DocElem elem) {
		if (elem.id == DocNodeId.doc) return
		cur := toHtmlNode(elem)
		htmlNode?.add(cur)
		htmlNode = cur
	}

	@NoDoc
	override Void elemEnd(DocElem elem) {
		if (elem.id == DocNodeId.doc) return
		if (htmlNode == null) return

		cur := htmlNode
		par := htmlNode?.parent
		res := null as Obj

		if (cur is HtmlElem) {
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
		}
		
		if (par == null)
			cur.print(str.out)
		
		htmlNode = par
	}

	@NoDoc
	override Void text(DocText docText) {
		htmlNode.elem.addText(docText.str)
	}	
	
	Str toHtml() { str.toStr }
	
	// ----

	virtual Obj? processLink(HtmlElem elem) {
		linkProcessors.eachWhile { it.process(elem) }
	}

	virtual Obj? processImage(HtmlElem elem) {
		imageProcessors.eachWhile { it.process(elem) }
		// ![YouTube vids][16x9]`https://www.youtube.com/embed/2SURpUQzUsE`
	}
	
	virtual Obj? processPara(HtmlElem elem) {
		paraProcessors.eachWhile { it.process(elem) }
	}

	virtual Obj? processPre(HtmlElem elem) {
		body	:= elem.text
		idx		:= body.index("\n") ?: -1
		cmdTxt	:= body[0..idx].trim
		cmd 	:= Uri(cmdTxt, false)		

		if (cmd?.scheme != null && preProcessors.containsKey(cmd.scheme)) {
			str		:= StrBuf()
			preText := body[idx..-1]
			replace	:= preProcessors[cmd.scheme].process(elem, cmd, preText)
			return replace
		}
		return elem
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
				if (html.id == null)
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
		return linkResolvers.eachWhile { it.resolve(elem, uri) }
	}

	private static Str toId(Str humanName) {
		Str.fromChars(humanName.fromDisplayName.chars.findAll { it.isAlphaNum || it == '_' || it == '-' })
	}
}

@Js
abstract class HtmlNode {
	private	HtmlNode?	_parent
	private HtmlNode[]	_nodes	:= HtmlNode[,]
//			Str:Obj?	meta	:= Str:Obj?[:]

	HtmlNode?	parent()	{ _parent }
	HtmlNode[]	nodes()		{ _nodes }
	HtmlElem?	elem()		{ this is HtmlElem ? this : parent?.elem }
	
	@Operator
	This add(HtmlNode node) {
		this._nodes.add(node)
		node._parent = this
		return this
	}
	
	HtmlNode replaceWith(HtmlNode node) {
		i := this._parent?._nodes?.indexSame(this)
			 this._parent?._nodes?.set(i, node)
		return node
	}
	
	abstract Void print(OutStream out)
	
	@NoDoc
	override Str toStr() { str := StrBuf(); print(str.out); return str.toStr }
}


@Js
class HtmlElem : HtmlNode {
	static const Str[] voidTags := "area base br col embed hr img input keygen link menuitem meta param source track wbr".split
	static const Str[] rawTags	:= "script style textarea title".split

	const	Str			name
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
			if (nodes.size == 1 && nodes.first is HtmlText) {
				htmlText := (HtmlText) nodes.first
				if (htmlText.isHtml)
					throw Err("Elem text is raw HTML: ${htmlText.text}")
				return htmlText.text
			}
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
		
		if (nodes.isEmpty && isVoid == false)
			out.writeChar('/')
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
	Str		text
	Bool	isHtml
	
	new make(Str text, Bool isHtml := false) {
		this.text	= text
		this.isHtml	= isHtml
	}
	
	Str getPlainText() {
		isHtml ? throw Err("Elem text is raw HTML: ${text}") : text
	}

	@NoDoc
	override Void print(OutStream out) {
		if (text.isEmpty) return
		if (isHtml || elem?.isRawText == true) out.writeChars(text); else out.writeXml(text)
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

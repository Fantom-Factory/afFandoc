using fandoc

**
** pre>
** render()
**   renderAttrs()
**     resolveLink()
**     renderClass()
**   renderBody()
**     renderPreBody()
** <pre
class HtmlDocWriter2 : DocWriter2 {
	
	DocNodeId:Str			cssClasses			:= DocNodeId:Str[:] { it.def = "" }
	Str:PreTextProcessor	preTextProcessors	:= Str:PreTextProcessor[:]
	LinkResolver[]			linkResolvers		:= LinkResolver[,]
	@NoDoc Bool				invalidLink
	
	static HtmlDocWriter2 original() {
		HtmlDocWriter2() {
			it.linkResolvers = [
				LinkResolver.passThroughResolver,
			]
		}
	}
	
	static HtmlDocWriter2 fullyLoaded() {
		HtmlDocWriter2() {
			it.linkResolvers = [
				LinkResolver.schemePassThroughResolver,
				LinkResolver.idPassThroughResolver,
				LinkResolver.passThroughResolver,
				FandocLinkResolver(),
			]
			it.preTextProcessors["table" ] = TablePreProcessor()
			it.preTextProcessors["syntax"] = SyntaxPreProcessor()
		}
	}
	
	override Void render(OutStream out, DocElem elem, Str body) {
		if (elem.isBlock)
			out.writeChar('\n')

		switch (elem.id) {
			case DocNodeId.pre:
				renderPreBody(out, elem, body)
			
			default:
				renderElem(out, elem, body)
		}		
	}
	
	override Str escapeText(DocElem elem, Str text) {
		elem.id == DocNodeId.pre ? text : text.toXml
	}
	
	virtual Void renderPreBody(OutStream out, DocElem elem, Str body) {
		idx		:= body.index("\n") ?: -1
		cmdTxt	:= body[0..idx].trim
		cmd 	:= Uri(cmdTxt, false)		

		if (cmd?.scheme != null && preTextProcessors.containsKey(cmd.scheme)) {
			preText := body[idx..-1]
			preTextProcessors[cmd.scheme].process(out, elem, cmd, preText)
		} else
			renderElem(out, elem, body.toXml)
	}

	virtual Void renderElem(OutStream out, DocElem elem, Str body) {
		out.writeChar('<').writeChars(elem.htmlName)
		renderAttrs(out, elem)
		
		if (isVoidElem(elem)) {
			if (body.size > 0)
				throw Err("Void Element '${elem.htmlName}' should NOT have content: ${body}")
			out.writeChar('/').writeChar('>')
		} else {
			out.writeChar('>')
			out.print(body)
			out.writeChar('<').writeChar('/').writeChars(elem.htmlName).writeChar('>')
		}
	}

	** Renders some standard element attributes, i.e. 'src' and 'alt' for 'img' tags.
	** 
	** Renders an 'id' attribute should the element's 'anchorId' not be null.
	virtual Void renderAttrs(OutStream out, DocElem elem) {
		if (elem.anchorId != null)
			attr(out, "id", elem.anchorId)
		
		switch (elem.id) {
			case DocNodeId.heading:
				heading := (Heading) elem
				if (heading.anchorId == null)
					attr(out, "id", toId(heading.title))	// FIXME title

			case DocNodeId.image:
				image := (Image) elem
				attr(out, "src", resolveLink(elem, image.uri) ?: image.uri)
				attr(out, "alt", image.alt)

			case DocNodeId.link:
				link := (Link) elem
				attr(out, "href", resolveLink(elem, link.uri) ?: link.uri)
			
			case DocNodeId.orderedList:
				ol := (OrderedList) elem
				attr(out, "style", "list-style-type: " + ol.style.htmlType)
		}

		renderClass(out, elem)
	}
	
	virtual Uri? resolveLink(DocElem elem, Str url) {
		uri := Uri(url, false)
		if (uri == null) return null
		scheme	:= uri.scheme == null ? null : url[0..<uri.scheme.size]
		link	:= linkResolvers.eachWhile { it.resolve(elem, scheme, uri) }
		invalidLink = link == null
		return link
	}

	virtual Void renderClass(OutStream out, DocElem elem) {
		cssClass := cssClasses[elem.id] ?: ""
		if (invalidLink) {
			invalidLink = false
			cssClass += " invalidLink"
		}

		switch (elem.id) {
			case DocNodeId.para:
				para := (Para) elem
				if (para.admonition != null)
					cssClass += " " + para.admonition.lower
		}

		if (cssClass?.trimToNull != null)
			attr(out, "class", cssClass.trim)
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

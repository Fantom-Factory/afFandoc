using fandoc
using fandoc::DocWriter 	as FDocWriter
using fandoc::HtmlDocWriter as FHtmlDocWriter

** A intelligent 'DocWriter' with useful method override hooks.
** Links that cannot be resolved are rendered with an 'invalidLink' CSS class and 'pre' blocks are processed 
**  
@Js
class HtmlDocWriter : DocWriter {
	
	DocNodeId:Str		cssClasses			:= DocNodeId:Str[:] { it.def = "" }
	Str:PreProcessor	preProcessors		:= Str:PreProcessor[:]
	LinkResolver[]		linkResolvers		:= LinkResolver[,]
	private Bool		invalidLink
	@NoDoc Str			invalidLinkClass	:= "invalidLink"
	
	** A simple HTML writer that mimics the original; no invalid links and no pre-block-processing.
	static HtmlDocWriter original() {
		HtmlDocWriter() {
			it.linkResolvers = [
				LinkResolver.passThroughResolver,
			]
		}
	}
	
	** A HTML writer that performs pre-block-processing for tables and syntax colouring.
	static HtmlDocWriter fullyLoaded() {
		HtmlDocWriter() {
			it.linkResolvers = [
				LinkResolver.schemePassThroughResolver,
				LinkResolver.pathAbsPassThroughResolver,
				LinkResolver.idPassThroughResolver,
				FandocLinkResolver(),
				LinkResolver.javascriptErrorResolver,
				LinkResolver.passThroughResolver,
			]
			it.preProcessors["table" ] = TablePreProcessor()
			if (Env.cur.runtime != "js")
				it.preProcessors["syntax"] = SyntaxPreProcessor()
		}
	}

	@NoDoc
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
	
	** Escapes the given text to XML, unless we're inside a 'pre' block.
	override Str escapeText(DocElem elem, Str text) {
		elem.id == DocNodeId.pre ? text : text.toXml
	}

	** Invokes a 'PreProcessor' should a matching one be found, else defaults to calling 'renderElem()'.
	virtual Void renderPreBody(OutStream out, DocElem elem, Str body) {
		idx		:= body.index("\n") ?: -1
		cmdTxt	:= body[0..idx].trim
		cmd 	:= Uri(cmdTxt, false)		

		if (cmd?.scheme != null && preProcessors.containsKey(cmd.scheme)) {
			preText := body[idx..-1]
			preProcessors[cmd.scheme].process(out, elem, cmd, preText)
		} else
			renderElem(out, elem, body.toXml)
	}

	** Invokes a 'PreProcessor' should a matching one be found, else defaults to calling 'renderElem()'.
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
				if (image.size != null) {
					sizes := image.size.split('x')
					if (sizes.getSafe(0)?.trimToNull != null)
						attr(out, "width", sizes[0])
					if (sizes.getSafe(1)?.trimToNull != null)
						attr(out, "height", sizes[1])
				}

			case DocNodeId.link:
				link := (Link) elem
				url  := Uri(link.uri, false)
				renderLinkAttrs(out, link, url)
			
			case DocNodeId.orderedList:
				ol := (OrderedList) elem
				attr(out, "style", "list-style-type: " + ol.style.htmlType)
		}

		renderClass(out, elem)
	}
	
	virtual Void renderLinkAttrs(OutStream out, Link link, Uri? url) {
		renderLinkHrefAttr(out, link)
	}

	virtual Void renderLinkHrefAttr(OutStream out, Link link) {
		attr(out, "href", resolveLink(link, link.uri) ?: link.uri)
	}

	** Calls the 'LinkResolvers' looking for valid links.
	virtual Uri? resolveLink(DocElem elem, Str url) {
		uri := Uri(url, false)
		if (uri == null) return null
		scheme	:= uri.scheme == null ? null : url[0..<uri.scheme.size]
		link	:= linkResolvers.eachWhile { it.resolve(elem, scheme, uri) }
		invalidLink = link == null
		return link
	}

	** Writes out 'class' attributes for some common scenarios.
	virtual Void renderClass(OutStream out, DocElem elem) {
		cssClass := cssClasses[elem.id] ?: ""
		if (invalidLink) {
			invalidLink = false
			cssClass += " ${invalidLinkClass}"
		}

		switch (elem.id) {
			case DocNodeId.para:
				para := (Para) elem
				if (para.admonition != null) {
					admon := para.admonition.all { it.isUpper } ? para.admonition.lower : para.admonition
					cssClass += " " + admon
				}
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

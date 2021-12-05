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
				Html5VideoProcessor(),
				VimeoProcessor(),
				YouTubeProcessor(),
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

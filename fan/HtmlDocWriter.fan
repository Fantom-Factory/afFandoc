using fandoc::Code
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
	Log					log							:= typeof.pod.log
	DocNodeId:Str		cssClasses					:= DocNodeId:Str[:] { it.def = "" }
	LinkResolver[]		linkResolvers				:= LinkResolver[,]
	ElemProcessor[]		linkProcessors				:= ElemProcessor[,]
	ElemProcessor[]		imageProcessors				:= ElemProcessor[,]
	ElemProcessor[]		paraProcessors				:= ElemProcessor[,]
	Str:PreProcessor	preProcessors				:= Str:PreProcessor[:]
	ElemProcessor?		invalidLinkProcessor
	protected StrBuf	str							:= StrBuf()
	protected HtmlNode?	htmlNode

	** A simple HTML writer that mimics the original; no invalid links and no pre-block-processing.
	static HtmlDocWriter original() {
		HtmlDocWriter {
			it.linkResolvers = [
				LinkResolver.passThroughResolver,
			]
		}
	}
	
	** A HTML writer that performs pre-block-processing for tables and syntax colouring.
	** 
	** (EveryLayout processors are preferred over BootStrap.)
	static HtmlDocWriter fullyLoaded() {
		HtmlDocWriter {
			hdw := it
			it.invalidLinkProcessor	= ElemProcessor.invalidLinkProcessor
			it.linkResolvers	= [
				LinkResolver.schemePassThroughResolver,
				LinkResolver.pathAbsPassThroughResolver,
				LinkResolver.idPassThroughResolver,
				LinkResolver.cssLinkResolver |Str? scheme, Uri url -> Uri?| {
					hdw.linkResolvers.eachWhile { it.resolve(scheme, url) }
				},
				FandocLinkResolver(),
				LinkResolver.javascriptErrorResolver,
				LinkResolver.passThroughResolver,
			]
			it.linkProcessors	= [
				ExternalLinkProcessor(),
				CssLinkProcessor(),
				MailtoProcessor("data-unscramble"),
				PdfLinkProcessor(),
			]
			it.paraProcessors	= [
				CssPrefixProcessor(),
			]
			it.imageProcessors	= [
				Html5VideoProcessor(),
				VimeoElProcessor(),
				YouTubeElProcessor(),
			]
			it.preProcessors	= [
				"table"			: TableProcessor(),
				"html"			: PreProcessor.htmlProcessor,
				"div"			: DivProcessor(it),
			]
			if (Env.cur.runtime != "js")
				it.preProcessors["syntax"] = SyntaxProcessor()
		}
	}
	
	** Writes the given elem to a string.
	Str writeToStr(DocElem elem) {
		olds := str
		oldn := htmlNode
		buf  := StrBuf()
		str   = buf
		htmlNode = null
		elem.write(this)
		str   = olds
		htmlNode = oldn
		return buf.toStr
	}

	** Parses the given string into a Fandoc document.
	** Document headers are automatically parsed if they're supplied.
	** Parsing errors are inserted into the start of the documents.
	Doc parse(Str fandoc, Str? loc := null) {
		// auto-detect headers - no legal fandoc should start with ***** unless it's a header!
		parser := FandocParser() { it.parseHeader = fandoc.trim.startsWith("*****"); silent = true }
		doc	   := parser.parse(loc ?: "afFandoc", fandoc.in, true)
		if (parser.errs.size > 0) {
			lines := fandoc.splitLines
			msg	  := "Fandoc errors" + (loc == null ? "" : " in ${loc}") + ":\n"

			// prepending errors is too specific to generalise in to afFandoc.
			parser.errs.eachr |err| {
				errLine := lines.getSafe(err.line, "").toCode
				p := Para().add(DocText("${err} - ")).add(Code().add(DocText(errLine))) { it.admonition = "parseErr" }
				doc.insert(0, p)
				msg += " - ${err} - ${errLine}\n"
			}
			log.warn(msg)
		}
		
		return doc
	}

	** Writes the given fandoc to a string.
	Str parseAndWriteToStr(Str fandoc, Str? loc := null) {
		doc := parse(fandoc, loc)
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
				case DocNodeId.image	: res = processImage(cur)
				case DocNodeId.link		: res = processLink	(cur)
				case DocNodeId.para		: res = processPara	(cur)
				case DocNodeId.pre		: res = processPre	(cur)
			}
			
			if (res != null && res !== cur) {
				if (res isnot Str && res isnot HtmlNode)
					throw UnsupportedErr("Unknown HtmlNode: ${res.typeof}")
				if (res is Str)
					res = HtmlText(res, true)
				cur = cur.replaceWith(res)
			}
		}
		
		if (par == null) {
			cur.print(str.out)
			// this \n makes debugging the HTML source SOOO much easier! 
			str.addChar('\n')
		}
		
		htmlNode = par
	}

	@NoDoc
	override Void text(DocText docText) {
		htmlNode.elem.addText(docText.str)
	}	
	
	Str toHtml() { str.toStr }
	
	// ----

	virtual Obj? processImage(HtmlElem elem) {
		imageProcessors.eachWhile { it.process(elem) }
	}

	virtual Obj? processLink(HtmlElem elem) {
		linkProcessors.eachWhile { it.process(elem) }
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
				if (image.size != null) {
					sizes := image.size.split('x')
					html["width"]	= sizes.getSafe(0)?.trimToNull
					html["height"]	= sizes.getSafe(1)?.trimToNull
				}
				src := resolveLink(html, image.uri)
				html["src"] = src ?: image.uri
				html["alt"] = image.alt

			case DocNodeId.link:
				link := (Link) elem
				url  := Uri(link.uri, false)
				href := resolveLink(html, link.uri)
				html["href"] = href ?: link.uri
		
			case DocNodeId.orderedList:
				ol := (OrderedList) elem
				html["style"] = "list-style-type: " + ol.style.htmlType
		}
		
		html.addClass(cssClasses[elem.id] ?: "")
		return html
	}
	
	** Calls the 'LinkResolvers' looking for valid links.
	virtual Uri? resolveLink(HtmlElem html, Str url) {
		res := null as Uri
		uri := Uri(url, false)
		if (uri != null) {
			scheme := uri.scheme == null ? null : url[0..<uri.scheme.size]
			res = linkResolvers.eachWhile { it.resolve(scheme, uri) }
		}
		
		if (res == null) {
			html["data-invalidLink"] = url
			invalidLinkProcessor?.process(html)
		}

		return res
	}

	private static Str toId(Str humanName) {
		Str.fromChars(humanName.fromDisplayName.chars.findAll { it.isAlphaNum || it == '_' || it == '-' })
	}
}

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
	Bool				allowComments				:= true
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
		docWriter := null as HtmlDocWriter
		return docWriter = HtmlDocWriter {
			hdw := it
			it.linkResolvers	= [
				LinkResolver.schemePassThroughResolver,
				LinkResolver.pathAbsPassThroughResolver,
				LinkResolver.idPassThroughResolver,
				LinkResolver.cssLinkResolver |Str? scheme, Uri uri -> Uri?| {
					hdw.resolveHref(scheme, uri)
				},
				FandocLinkResolver(),
				LinkResolver.passThroughResolver,
			]
			it.linkProcessors	= [
				ExternalLinkProcessor(),
				CssLinkProcessor(),
				MailtoProcessor("data-unscramble"),
				JavascriptLinkProcessor(),
			]
			it.paraProcessors	= [
				CssPrefixProcessor(),
			]
			it.imageProcessors	= [
				Html5VideoProcessor(),
				VimeoProcessor(),
				YouTubeProcessor(),
			]
			it.preProcessors	= [
				"table"			: TableProcessor() |Str fandoc->Str| { docWriter.parseAndWriteToStr(fandoc, "tableCell:")},
				"html"			: PreProcessor.htmlProcessor,
				"div"			: DivProcessor() |Str fandoc->Str| { docWriter.parseAndWriteToStr(fandoc, "div:")},
			]
			if (Env.cur.runtime != "js")
				it.preProcessors["syntax"] = SyntaxProcessor()
		}
	}
	
	** Writes the given elem to a string.
	** 
	** Calls to this method *may* be nested.
	virtual Str writeToStr(DocElem elem) {
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

	** Writes the given fandoc to a string.
	** 
	** Calls to this method *may* be nested.
	virtual Str parseAndWriteToStr(Str fandoc, Str? loc := null) {
		doc := parse(fandoc, loc)
		return writeToStr(doc)
	}	

	** Parses the given string into a Fandoc document.
	** Document headers are automatically parsed if they're supplied.
	** Parsing errors are inserted into the start of the documents.
	virtual Doc parse(Str fandoc, Str? loc := null) {
		// auto-detect headers - no legal fandoc should start with ***** unless it's a header!
		parser := FandocParser() { it.parseHeader = fandoc.trim.startsWith("*****"); silent = true }
		doc	   := parser.parse(loc ?: "afFandoc", fandoc.in, true)
		if (parser.errs.size > 0) {
			lines := fandoc.splitLines
			msgs  := "Fandoc errors" + (loc == null ? "" : " in ${loc}") + ":\n"

			// prepending errors is too specific to generalise in to afFandoc.
			parser.errs.eachr |err| {
				errLine := lines.getSafe(err.line-1, "").toCode
				errMsg	:= err.msg
				// don't add the line num if it's already in the err msg
				if (errMsg.endsWith(err.line.toStr) == false)
					errMsg += " (${err.line})"
				errMsg += " - "
				p := Para().add(DocText(errMsg)).add(Code().add(DocText(errLine))) { it.admonition = "parseErr" }
				doc.insert(0, p)
				msgs += " - ${errMsg}${errLine}\n"
			}
			log.warn(msgs)
		}

		return doc
	}

	@NoDoc
	override Void docStart(Doc doc) { }
	
	@NoDoc
	override Void docEnd(Doc doc) { }
	
	@NoDoc
	override Void elemStart(DocElem elem) {
		if (elem.id == DocNodeId.doc)		return
		
		// comments are hard coded - its... just easier this way.
		if (allowComments && elem.toText.startsWith(".//")) {
			htmlNode = null
			return
		}

		cur := toHtmlNode(elem)
		htmlNode?.add(cur)
		htmlNode = cur
	}

	@NoDoc
	override Void elemEnd(DocElem elem) {
		if (elem.id == DocNodeId.doc) return
		if (htmlNode == null) return

		cur := htmlNode
		res := null as Obj

		if (cur is HtmlElem) {
			switch (elem.id) {
				case DocNodeId.image	: res = processImage(cur, elem)
				case DocNodeId.link		: res = processLink	(cur, elem)
				case DocNodeId.para		: res = processPara	(cur, elem)
				case DocNodeId.pre		: res = processPre	(cur, elem)
			}
			
			if (res != null && res !== cur) {
				if (res isnot Str && res isnot HtmlNode)
					throw UnsupportedErr("Unknown HtmlNode: ${res.typeof}")
				if (res is Str)
					res = HtmlText(res, true)
				cur = cur.replaceWith(res)
			}
		}

		// print out top level nodes
		// check that the elem has not been removed
		par := htmlNode?.parent
		if (par == null && cur._killMe == false) {
			cur.print(str.out)
			// this \n makes debugging the HTML source SOOO much easier! 
			str.addChar('\n')
		}
		
		htmlNode = par
	}

	@NoDoc
	override Void text(DocText docText) {
		htmlNode?.elem?.addText(docText.str)
	}	
	
	Str toHtml() { str.toStr }
	
	// ----

	virtual Obj? processImage(HtmlElem elem, DocElem src) {
		imageProcessors.eachWhile { it.process(elem, src) }
	}

	virtual Obj? processLink(HtmlElem elem, DocElem src) {
		linkProcessors.eachWhile { it.process(elem, src) }
	}
	
	virtual Obj? processPara(HtmlElem elem, DocElem src) {
		paraProcessors.eachWhile { it.process(elem, src) }
	}

	virtual Obj? processPre(HtmlElem elem, DocElem src) {
		body	:= elem.text
		idx		:= body.index("\n") ?: -1
		cmdTxt	:= body[0..idx].trim
		cmd 	:= Uri(cmdTxt, false)		

		if (cmd?.scheme != null && preProcessors.containsKey(cmd.scheme)) {
			str		:= StrBuf()
			preText := body[idx..-1]
			replace	:= preProcessors[cmd.scheme].process(elem, src, cmd, preText)
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
					style	:= ""
					sizes	:= image.size.split('x')
					width	:= sizes.getSafe(0)?.trimToNull?.toInt(10, false)
					height	:= sizes.getSafe(1)?.trimToNull?.toInt(10, false)
					
					// set size via style so it overrides any arbitrary CSS styles 
					if (width  != null)	style +=   "width: ${width}px;"
					if (height != null)	style += " height: ${height}px;"
					if (style.size > 0)
						html["style"] = style
				}
				src := resolveLink(html, elem, image.uri)
				html["src"] = src ?: image.uri
				html["alt"] = image.alt

			case DocNodeId.link:
				link := (Link) elem
				href := resolveLink(html, elem, link.uri)
				html["href"] = href ?: link.uri
		
			case DocNodeId.orderedList:
				ol := (OrderedList) elem
				html["style"] = "list-style-type: " + ol.style.htmlType
		}
		
		html.addClass(cssClasses[elem.id] ?: "")
		return html
	}
	
	** Calls the 'LinkResolvers' looking for valid links.
	virtual Uri? resolveLink(HtmlElem html, DocElem src, Str url) {
		res := null as Uri
		uri := Uri(url, false)
		if (uri != null) {
			scheme := uri.scheme == null ? null : url[0..<uri.scheme.size]
			res = resolveHref(scheme, uri)
		}

		if (res == null)
			onUnresolvedLink(html, src, url)

		return res
	}

	** I can't lie, this is hacky callback hook for use by CssLinkResolver.
	virtual Uri? resolveHref(Str? scheme, Uri uri) {
		linkResolvers.eachWhile { it.resolve(scheme, uri) }
	}

	** Called when a URL could not be resolved.
	** The default is to add a data attr of 'data-unresolvedLink' with the URL.
	virtual Void onUnresolvedLink(HtmlElem html, DocElem src, Str url) {
		html["data-unresolvedLink"] = url
	}

	private static Str toId(Str humanName) {
		Str.fromChars(humanName.fromDisplayName.chars.findAll { it.isAlphaNum || it == '_' || it == '-' })
	}
}

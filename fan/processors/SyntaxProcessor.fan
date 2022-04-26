using syntax::SyntaxDoc
using syntax::SyntaxRules
using syntax::SyntaxType

** A 'PreProcessor' that provides syntax highlighting for code blocks.
** 
** Not available in Javascript.
class SyntaxProcessor : PreProcessor {

	Bool renderLineIds
	
	** Syntax aliases.
	Str:Str	aliases := Str:Str[
		"fantom" : "fan"
	]

	** HTML tags to render for each syntax type.
	SyntaxType:Str? htmlTags := [
		SyntaxType.text		: null,
		SyntaxType.bracket	: "b",
		SyntaxType.keyword	: "i",
		SyntaxType.literal	: "em",
		SyntaxType.comment	: "s",	// don't use 'q' as wot 'SyntaxType' does; as firefox, when CTRL+C, AWAYS adds quotes around it! 
	]

	** CSS classes to be rendered with the syntax tags.
	SyntaxType:Str? cssClasses := [
		SyntaxType.text		: null,
		SyntaxType.bracket	: null,
		SyntaxType.keyword	: null,
		SyntaxType.literal	: null,
		SyntaxType.comment	: null, 
	]
	
	@NoDoc
	override Obj? process(HtmlElem elem, Uri cmd, Str preText) {
		writeSyntax(cmd.pathStr.trim, "syntax", preText)
	}

	HtmlElem writeSyntax(Str extension, Str cssClasses, Str text) {
		if (aliases.containsKey(extension))
			extension = aliases[extension]		

		ext	:= extension.lower
		div := HtmlElem("div").addClass(cssClasses).addClass(ext)

		// trim new lines, but not spaces
		while (text.startsWith("\n"))
			text = text[1..-1]
		while (text.endsWith("\n"))
			text = text[0..-2]

		rules := loadSyntax(ext)
		if (rules == null)
			div.add(HtmlElem("pre").addText(text))

		else {			
			parserType	:= Type.find("syntax::SyntaxParser")
			parser		:= parserType.method("make").call(rules)
			parserType.field("tabsToSpaces").set(parser, 4)
			synDoc		:= parserType.method("parse").callOn(parser, [text.in])
			innerHtml	:= writeLines(synDoc, renderLineIds)
			div.addHtml(innerHtml)
		}

		return div
	}
	
	virtual SyntaxRules? loadSyntax(Str ext) {
		rules := SyntaxRules.loadForExt(ext)
		if (rules == null && ext.size > 0)
			typeof.pod.log.warn("Could not find syntax file for '${ext}'")
		return rules
	}
	
	private Str writeLines(SyntaxDoc doc, Bool renderLineIds) {
		str := StrBuf()
		out	:= str.out
		out.print("<pre>")
		doc.eachLine |line| { 
			if (renderLineIds)
				out.print("<span id=\"line${line.num}\">")

			line.eachSegment |type, text| {
				html := htmlTags[type]
				if (html != null) {
					out.writeChar('<').print(html)
					cssClass := cssClasses[type]
					if (cssClass != null)
						out.print(" class=\"").print(cssClass).writeChar('"')
					out.writeChar('>')
				}
				out.writeXml(text)
				if (html != null)
					out.writeChars("</").print(html).writeChar('>')
			}

			if (renderLineIds)
				out.print("</span>")
			out.writeChar('\n')		
		}
		out.print("</pre>")
		return str.toStr
	}
}

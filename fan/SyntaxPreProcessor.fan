using fandoc::DocElem
using syntax::SyntaxDoc
using syntax::SyntaxRules
using syntax::SyntaxType

** A 'PreProcessor' that provides syntax highlighting for code blocks.
** 
** Not available in Javascript.
class SyntaxPreProcessor : PreProcessor {

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
	override Void process(OutStream out, DocElem elem, Uri cmd, Str preText) {
		writeSyntax(out, cmd.pathStr.trim, "syntax", preText)
	}

	Void writeSyntax(OutStream out, Str extension, Str cssClasses, Str text) {
		if (aliases.containsKey(extension))
			extension = aliases[extension]		
		
		ext	:= extension.lower
		out.print("<div class=\"${cssClasses} ${ext}\">")

		// trim new lines, but not spaces
		while (text.startsWith("\n"))
			text = text[1..-1]
		while (text.endsWith("\n"))
			text = text[0..-2]
		
		rules := SyntaxRules.loadForExt(ext)
		if (rules == null) {
			typeof.pod.log.warn("Could not find syntax file for '${ext}'")
			out.print("<pre>").writeXml(text).print("</pre>")

		} else {			
			parserType	:= Type.find("syntax::SyntaxParser")
			parser		:= parserType.method("make").call(rules)
			parserType.field("tabsToSpaces").set(parser, 4)
			synDoc := parserType.method("parse").callOn(parser, [text.in])
			writeLines(out, synDoc, renderLineIds)
		}
		
		out.print("</div>")
	}
	
	private Void writeLines(OutStream out, SyntaxDoc doc, Bool renderLineIds) {
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
	}
}

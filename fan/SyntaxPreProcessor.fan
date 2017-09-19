using fandoc::DocElem
using syntax::SyntaxDoc
using syntax::SyntaxRules
using syntax::SyntaxType

class SyntaxPreProcessor : PreTextProcessor {

	Bool renderLineIds
	
	Str:Str	aliases := Str:Str[
		"fantom" : "fan"
	]

	SyntaxType:Str? htmlTags := [
		SyntaxType.text		: null,
		SyntaxType.bracket	: "b",
		SyntaxType.keyword	: "i",
		SyntaxType.literal	: "em",
		SyntaxType.comment	: "s",	// don't use 'q' as wot 'SyntaxType' does; as firefox, when CTRL+C, AWAYS adds quotes around it! 
	]

	SyntaxType:Str? cssClasses := [
		SyntaxType.text		: null,
		SyntaxType.bracket	: null,
		SyntaxType.keyword	: null,
		SyntaxType.literal	: null,
		SyntaxType.comment	: null, 
	]
	
	override Void process(OutStream out, DocElem elem, Uri cmd, Str preText) {
		ext := cmd.pathStr.trim
		if (aliases.containsKey(ext))
			ext = aliases[ext]

		// trim new lines, but not spaces
		while (preText.startsWith("\n"))
			preText = preText[1..-1]
		while (preText.endsWith("\n"))
			preText = preText[0..-2]

		writeSyntax(out, ext, preText)
	}

	private Void writeSyntax(OutStream out, Str extension, Str text) {
		ext	:= extension.lower
		out.print("<div class=\"syntax ${ext}\">")
		
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

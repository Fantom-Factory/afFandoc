using fandoc::DocElem
using syntax::SyntaxDoc
using syntax::SyntaxRules
using syntax::SyntaxType

** A 'PreProcessor' that provides syntax highlighting for code blocks.
** 
** Not available in Javascript.
class SyntaxProcessor : PreProcessor {

	** Beware if setting to true - only ONE syntax may be rendered per page.
	** todo: specify a lineId pefix.
	Bool renderLineIds	:= false

	** Syntax aliases.
	Str:Str	aliases := Str:Str[
		"fantom" : "fan",
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
	
	new make([Str:Str]? aliases := null) {
		if (aliases != null)
			this.aliases.setAll(aliases)
	}
	
	@NoDoc
	override Obj? process(HtmlElem elem, DocElem src, Uri cmd, Str preText) {
		writeSyntax(cmd.pathStr.trim, preText)
	}

	HtmlElem writeSyntax(Str ext, Str text) {
		splits		:= ext.split
		extension	:= splits.first.lower
		if (aliases.containsKey(extension))
			extension = aliases[extension]

		pre := HtmlElem("pre").addClass("syntax").set("data-syntax", extension)
		
		if (splits.size > 1)
			CssPrefixProcessor.apply(pre, splits[1])

		// trim new lines, but not spaces
		while (text.startsWith("\n"))
			text = text[1..-1]
		while (text.endsWith("\n"))
			text = text[0..-2]

		rules := loadSyntax(extension)
		if (rules == null)
			pre.addText(text)

		else {			
			parserType	:= Type.find("syntax::SyntaxParser")
			parser		:= parserType.method("make").call(rules)
			parserType.field("tabsToSpaces").set(parser, 4)
			synDoc		:= parserType.method("parse").callOn(parser, [text.in])
			writeLines(pre, synDoc, renderLineIds)
		}

		return pre
	}
	
	virtual SyntaxRules? loadSyntax(Str ext) {
		rules := SyntaxRules.loadForExt(ext)
		
		// special case for non-std fandoc
		if (rules == null && ext == "fandoc")
			rules = typeof.pod.file(`/etc/syntax/syntax-fandoc.fog`).readObj

		if (rules == null && ext.size > 0)
			typeof.pod.log.warn("Could not find syntax file for '${ext}'")

		return rules
	}
	
	private Void writeLines(HtmlElem elem, SyntaxDoc doc, Bool renderLineIds) {
		doc.eachLine |line| {
			row := elem
			if (renderLineIds) {
				span := HtmlElem("Span").setId("line${line.num}")
				row.add(span)
				row = span
			}

			line.eachSegment |type, text| {
				seg := row
				tag := htmlTags[type]
				if (tag != null) {
					seg  = HtmlElem(tag)
					css := cssClasses[type]
					if (css != null)
						seg.addClass(css)
					row.add(seg)
					row = seg
				}
				seg.text = seg.text + text
			}
			row.text = row.text + "\n"
		}
	}
}

using fandoc::FandocParser
using fandoc::DocNodeId

class TestHtmlDocWriter : Test {
	
	private HtmlWriter2? dw2
	

	
	// --- test old functionality ----

	Void testBasic() {
		out := write("Hello!")
		verifyEq(out, "<p>Hello!</p>")
	}

	Void testIds() {
		out := write("Dude [#sweet]\n====")
		verifyEq(out, "<h3 id=\"sweet\">Dude</h3>")
	}

	Void testLinksHaveHref() {
		out := write("[Link]`http://href/`")
		verifyEq(out, "<p><a href=\"http://href/\">Link</a></p>")
	}
	
	Void testImagesHaveSrcAndAlt() {
		out := write("![alt text]`http://href/`")
		verifyEq(out, "<p><img src=\"http://href/\" alt=\"alt text\"/></p>")
	}

	Void testOrderedListStyle() {
		out := write(" 1. Dude\n 2. Sweet")
		verifyEq(out, "<ol style=\"list-style-type: decimal\"><li>Dude</li><li>Sweet</li></ol>")
	}

	
	
	// --- test new functionality ----
	
	Void testIdsForHeadingAlwaysRendered() {
		out := write("Dude\n====")
		verifyEq(out, "<h3 id=\"dude\">Dude</h3>")
	}
	
	Void testParaAdmonition() {
		out := write("LEAD: Hello!")
		verifyEq(out, "<p class=\"lead\">Hello!</p>")		
	}

	Void testExtraCssClass() {
		dw2.cssClasses[DocNodeId.code] = "acmeClass"
		out := write("'Hello!'")
		verifyEq(out, "<p><code class=\"acmeClass\">Hello!</code></p>")		
	}

	Void testPreTextStillEscaped() {
		out := write("pre>\naxonatorKey = <secretKey>\n<pre")
		verifyEq(out, "<pre>axonatorKey = &lt;secretKey></pre>")		
	}

	Void testImagesAndText() {
		out := write("![alt text]`http://href/`\n\nSome text\n")
		verifyEq(out, "<p><img src=\"http://href/\" alt=\"alt text\"/></p><p>Some text</p>")
	}
	
	// --------
	
	override Void setup() {
		dw2 = HtmlWriter2.original
	}
	
	private Str write(Str fandoc) {
		doc := FandocParser().parseStr(fandoc)
		return dw2.writeToStr(doc).replace("\n", "")
	}
}

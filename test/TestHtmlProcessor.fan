
internal class TestHtmlProcessor : FandocTest {
	
	Void testHtml() {
		table := 
		"pre>
		 html:
		 <div class='classy'>text</div>
		 <pre"
		out := write(table)
		verifyEq(out, """<div class='classy'>text</div>""")
	}

	Void testHtmlWithCss() {
		// it's too complicated to merge styles and classes right now, 
		// so just ignore CSS prefixes with html:
		table := 
		"pre>
		 html: .some.css.{color:red}
		 <div class='classy'>text</div>
		 <pre"
		out := write(table)
		verifyEq(out, """<div class='classy'>text</div>""")
	}
}

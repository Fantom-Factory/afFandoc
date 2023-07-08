
internal class TestTableProcessor : Test {
	
	Void testTableCss() {
		table := 
		"pre>
		 table: .some.css.{color:red}
		 thead
		 -----
		 tbody
		 <pre"
		out := write(table)
		verifyEq(out, """<table class="some css" style="color:red"><thead><tr><th>thead</th></tr></thead><tbody><tr><td>tbody</td></tr></tbody></table>""")
	}

	private Str write(Str fandoc) {
		HtmlDocWriter.fullyLoaded.parseAndWriteToStr(fandoc).trimEnd
	}
}

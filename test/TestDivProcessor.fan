
internal class TestDivProcessor : Test {
	
	Void testLinks() {
		out := null as Str

		out = write("  div: .classy\n  To **Boldly** go.")
		verifyEq(out, """<div class="classy"><p>To <strong>Boldly</strong> go.</p></div>""")

		out = write("  div: .classy.this.is\n  To **Boldly** go.")
		verifyEq(out, """<div class="classy this is"><p>To <strong>Boldly</strong> go.</p></div>""")
	}
	
	private Str write(Str fandoc) {
		HtmlDocWriter.fullyLoaded.parseAndWriteToStr(fandoc).trimEnd

	}	
}

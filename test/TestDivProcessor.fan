
internal class TestDivProcessor : Test {
	
	Void testLinks() {
		out := null as Str

		out = write("  div: .classy\n  To **Boldly** go.")
		verifyEq(out, """<div class="class"><p>To <strong>Boldly</strong> go.</p></div>""")
	}
	
	private Str write(Str fandoc) {
		HtmlDocWriter.fullyLoaded.parseAndWriteToStr(fandoc).trimEnd

	}	
}

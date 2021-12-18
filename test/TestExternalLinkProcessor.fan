
internal class TestExternalLinkProcessor : Test {
	
	Void testLinks() {
		out := null as Str

		out = write("[link]`/to/nowhere`")
		verifyEq(out, """<p><a href="/to/nowhere">link</a></p>""")

		out = write("[link]`http://www.somewhere.com/lets/go!`")
		verifyEq(out, """<p><a href="http://www.somewhere.com/lets/go!" target="_blank">link</a></p>""")
	}
	
	private Str write(Str fandoc) {
		HtmlDocWriter.fullyLoaded.parseAndWriteToStr(fandoc).trimEnd
	}	
}


internal class TestMailtoLinkProcessor : Test {
	
	Void testLinks() {
		out := null as Str

		out = write("[contact]`mailto:no@one.com`")
		verifyEq(out, """<p><a href="#" data-unscramble="gbvB0buVmLj9Wb">contact</a></p>""")

		out = write("`mailto:no@one.com`")
		verifyEq(out, """<p><a href="#" data-unscramble="gbvB0buVmLj9Wb">----------</a></p>""")
	}
	
	private Str write(Str fandoc) {
		HtmlDocWriter.fullyLoaded.parseAndWriteToStr(fandoc)
	}	
}

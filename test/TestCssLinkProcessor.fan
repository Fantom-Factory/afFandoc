
internal class TestCssLinkProcessor : Test {
	
	Void testLinks() {
		out := null as Str

		out = write("[spanny]`.some.class`")
		verifyEq(out, """<p><span class="some class">spanny</span></p>""")

		out = write("[spanny]`.{color:red}`")
		verifyEq(out, """<p><span style="color:red">spanny</span></p>""")
		
		out = write("[spanny]`.some.class.{color:red}`")
		verifyEq(out, """<p><span class="some class" style="color:red">spanny</span></p>""")
		
		out = write("[spanny]`.some.class http://dude.com`")
		verifyEq(out, """<p><a href="http://dude.com" class="some class">spanny</a></p>""")

		out = write("[spanny]`.{color:red} /meh`")
		verifyEq(out, """<p><a href="/meh" style="color:red">spanny</a></p>""")
		
		out = write("[spanny]`.some.class.{color:red} cool.pdf`")
		verifyEq(out, """<p><a href="cool.pdf" class="some class" style="color:red" target="_blank">spanny</a></p>""")
	}
	
	private Str write(Str fandoc) {
		HtmlDocWriter.fullyLoaded.parseAndWriteToStr(fandoc).trimEnd
	}	
}

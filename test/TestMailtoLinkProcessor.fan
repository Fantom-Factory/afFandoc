
internal class TestMailtoLinkProcessor : FandocTest {
	
	Void testLinks() {
		out := null as Str

		out = write("[contact]`mailto:no@one.com`")
		verifyEq(out, """<p><a href="#" data-unscramble="gbvB0buVmLj9Wb" target="_top" rel="nofollow">contact</a></p>""")

		out = write("`mailto:no@one.com`")
		verifyEq(out, """<p><a href="#" data-unscramble="gbvB0buVmLj9Wb" target="_top" rel="nofollow">----------</a></p>""")
	}
}

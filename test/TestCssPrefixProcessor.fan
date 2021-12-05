
class TestCssPrefixProcessor : Test {
	
	Void testCssPrefixes() {
		out := null as Str

		out = write(".classy This is.")
		verifyEq(out, """<p class="classy">This is.</p>""")

		out = write("\\.classy This is not.")
		verifyEq(out, """<p>.classy This is not.</p>""")

		out = write(".{stylish} This is.")
		verifyEq(out, """<p style="stylish">This is.</p>""")

		out = write("\\.{stylish} This is not.")
		verifyEq(out, """<p>.{stylish} This is not.</p>""")
	}
	
	private Str write(Str fandoc) {
		HtmlDocWriter.fullyLoaded.parseAndWriteToStr(fandoc)
	}
}

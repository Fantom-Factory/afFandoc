
internal class TestCssPrefixProcessor : Test {
	
	Void testCssPrefixes() {
		out := null as Str

		out = write(".classy This is.")
		verifyEq(out, """<p class="classy">This is.</p>""")

		out = write(".very.classy This is.")
		verifyEq(out, """<p class="very classy">This is.</p>""")

		out = write("\\.classy This is not.")
		verifyEq(out, """<p>.classy This is not.</p>""")

		out = write(".{stylish} This is.")
		verifyEq(out, """<p style="stylish">This is.</p>""")

		out = write(".very.{stylish} This is.")
		verifyEq(out, """<p class="very" style="stylish">This is.</p>""")

		out = write(".{stylish}.very This is.")
		verifyEq(out, """<p style="stylish" class="very">This is.</p>""")

		out = write("\\.{stylish} This is not.")
		verifyEq(out, """<p>.{stylish} This is not.</p>""")
	}
	
	Void testMultiParas() {
		out := null as Str

		// make sure inner elems are not overwritten
		out = write(".cta [foo]`/bar`")
		verifyEq(out, """<p class="cta"><a href="/bar">foo</a></p>""")
	}
	
	private Str write(Str fandoc) {
		HtmlDocWriter.fullyLoaded.parseAndWriteToStr(fandoc)
	}
}

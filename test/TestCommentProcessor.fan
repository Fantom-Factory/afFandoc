
internal class TestCommentProcessor : Test {
	
	Void testComments() {
		out := null as Str

		out = write("This is a para.\n\n.// This is not.\n\nThis is another para.")
		verifyEq(out, """<p>This is a para.</p>\n<p>This is another para.</p>""")

		out = write("pre>\ntext\n<pre\n\npre>\n.//syntax: axon\na:b\n<pre")
		verifyEq(out, """<pre>text\n</pre>""")
	}

	private Str write(Str fandoc) {
		HtmlDocWriter.fullyLoaded.parseAndWriteToStr(fandoc).trimEnd
	}	
}

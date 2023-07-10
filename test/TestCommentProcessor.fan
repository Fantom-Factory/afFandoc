
internal class TestCommentProcessor : FandocTest {
	
	Void testComments() {
		out := null as Str

		out = write("This is a para.\n\n.// This is not.\n\nThis is another para.")
		verifyEq(out, """<p>This is a para.</p>\n<p>This is another para.</p>""")

		out = write("pre>\ntext\n<pre\n\npre>\n.//syntax: axon\na:b\n<pre")
		verifyEq(out, """<pre>text\n</pre>""")

		out = write("This is a para with './/' embedded.")
		verifyEq(out, """<p>This is a para with <code>.//</code> embedded.</p>""")

		// make sure all child node are also removed
		out = write(".// This is a comment with **bold** text.")
		verifyEq(out, "")

		out = write(".// This is a comment with [a link]`.link`.")
		verifyEq(out, "")
	}
}

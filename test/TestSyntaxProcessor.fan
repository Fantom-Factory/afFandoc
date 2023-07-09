
internal class TestSyntaxProcessor : Test {
	
	Void testSyntax() {
		out := null as Str

		out = write("  syntax: axon\n  a:b")
		verifyEq(out, """<pre class="syntax" data-syntax="axon">a:b\n</pre>""")

		out = write("  syntax: axon .classy.{color:red}\n  a:b\n")
		verifyEq(out, """<pre class="syntax classy" data-syntax="axon" style="color:red">a:b\n</pre>""")
	}
	
	private Str write(Str fandoc) {
		HtmlDocWriter.fullyLoaded.parseAndWriteToStr(fandoc).trimEnd
	}	
}


internal class TestDivProcessor : FandocTest {
	
	Void testLinks() {
		out := null as Str

		out = write("  div: .classy\n  To **Boldly** go.")
		verifyEq(out, """<div class="classy"><p>To <strong>Boldly</strong> go.</p></div>""")

		out = write("  div: .classy.this.is\n  To **Boldly** go.")
		verifyEq(out, """<div class="classy this is"><p>To <strong>Boldly</strong> go.</p></div>""")

		// allow tab chars so the URI may mimic a YAML property
		out = write("  div\t\t:\tTest tab chars in scheme")
		verifyEq(out, """<div></div>""")

		out = write("  div\t\t:\tTest tab chars in scheme\n  Body")
		verifyEq(out, """<div><p>Body</p></div>""")
	}
}

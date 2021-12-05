
internal class TestVimeoProcessor : Test {
	
	Void testBasic() {
		out := write("![meh]`https://vimeo.com/11712103`")
		verifyEq(out, """<p><div class="vimeoVideo d-print-none embed-responsive embed-responsive-16by9"><iframe class="embed-responsive-item" src="https://player.vimeo.com/video/11712103" allowfullscreen allow="fullscreen" style="border: none;" title="meh"/></div></p>""")
	}
	
	Void testAspect() {
		out := write("![meh][4x3]`https://vimeo.com/11712103`")
		verifyEq(out, """<p><div class="vimeoVideo d-print-none embed-responsive embed-responsive-4by3"><iframe class="embed-responsive-item" src="https://player.vimeo.com/video/11712103" allowfullscreen allow="fullscreen" style="border: none;" title="meh"/></div></p>""")
	}

	private Str write(Str fandoc) {
		HtmlDocWriter.fullyLoaded.parseAndWriteToStr(fandoc)
	}
}

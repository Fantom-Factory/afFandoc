
class TestYouTubeImageLinks : Test {
	
	Void testBasic() {
		out := write("![meh]`https://youtu.be/2SURpUQzUsE`")
		verifyEq(out, """<p><div class="youtubeVideo d-print-none embed-responsive embed-responsive-16by9"><iframe class="embed-responsive-item" src="https://www.youtube.com/embed/2SURpUQzUsE" allowfullscreen allow="fullscreen" style="border: none;" title="meh"/></div></p>""")
	}
	
	Void testAspect() {
		out := write("![meh][4x3]`https://youtu.be/2SURpUQzUsE`")
		verifyEq(out, """<p><div class="youtubeVideo d-print-none embed-responsive embed-responsive-4by34by34by34by3"><iframe class="embed-responsive-item" src="https://www.youtube.com/embed/2SURpUQzUsE" allowfullscreen allow="fullscreen" style="border: none;" title="meh"/></div></p>""")
	}

	private Str write(Str fandoc) {
		HtmlDocWriter.fullyLoaded.parseAndWriteToStr(fandoc).replace("\n", "")
	}
}

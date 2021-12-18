
internal class TestYouTubeProcessor : Test {
	
	Void testBasic() {
		out := write("![meh]`https://youtu.be/2SURpUQzUsE`")
		verifyEq(out, """<div><div class="youtubeVideo d-print-none embed-responsive embed-responsive-16by9"><iframe class="embed-responsive-item" src="https://www.youtube.com/embed/2SURpUQzUsE" allowfullscreen allow="fullscreen" style="border: none;" title="meh"></iframe></div></div>""")
	}
	
	Void testAspect() {
		out := write("![meh][4x3]`https://youtu.be/2SURpUQzUsE`")
		verifyEq(out, """<div><div class="youtubeVideo d-print-none embed-responsive embed-responsive-4by3"><iframe class="embed-responsive-item" src="https://www.youtube.com/embed/2SURpUQzUsE" allowfullscreen allow="fullscreen" style="border: none;" title="meh"></iframe></div></div>""")
	}

	private Str write(Str fandoc) {
		HtmlDocWriter.fullyLoaded.parseAndWriteToStr(fandoc).trimEnd
	}
}

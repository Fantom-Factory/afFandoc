
internal class TestHtml5VideoProcessor : Test {
	
	Void testBasic() {
		out := write("![meh]`/video/catlolz.mp4`")
		verifyEq(out, """<p><div class="htmlVideo d-print-none embed-responsive embed-responsive-16by9" title="meh"><video class="embed-responsive-item" muted playsinline controls><source src="/video/catlolz.mp4" type="video/mp4"><p>Your browser does not support HTML5 video. Here is a <a href="/video/catlolz.mp4">link to the video</a> instead.</p></video></div></p>""")
	}
	
	Void testAspect() {
		out := write("![meh][4x3]`/video/catlolz.webm`")
		verifyEq(out, """<p><div class="htmlVideo d-print-none embed-responsive embed-responsive-4by3" title="meh"><video class="embed-responsive-item" muted playsinline controls><source src="/video/catlolz.webm" type="video/webm"><p>Your browser does not support HTML5 video. Here is a <a href="/video/catlolz.webm">link to the video</a> instead.</p></video></div></p>""")
	}

	private Str write(Str fandoc) {
		HtmlDocWriter.fullyLoaded.parseAndWriteToStr(fandoc)
	}
}


internal class TestYouTubeProcessor : Test {
	
	Void testBasic() {
		out := write("![meh]`https://youtu.be/2SURpUQzUsE`")
		verifyEq(out, """<div class="youtubeVideo"><div class="el-frame" style="--el-frame-width:16; --el-frame-height:9"><iframe src="https://www.youtube.com/embed/2SURpUQzUsE" allowfullscreen allow="fullscreen" style="border: none;"></iframe></div></div>""")
	}
	
	Void testSize() {
		out := write("![meh][200x100]`https://youtu.be/2SURpUQzUsE`")
		verifyEq(out, """<div class="youtubeVideo" style="width:200px; height:100px;"><div class="el-frame" style="--el-frame-width:16; --el-frame-height:9"><iframe src="https://www.youtube.com/embed/2SURpUQzUsE" allowfullscreen allow="fullscreen" style="border: none;"></iframe></div></div>""")
	}

	Void testAspect() {
		out := write("![meh]`https://youtu.be/2SURpUQzUsE?aspectRatio=2x1`")
		verifyEq(out, """<div class="youtubeVideo"><div class="el-frame" style="--el-frame-width:2; --el-frame-height:1"><iframe src="https://www.youtube.com/embed/2SURpUQzUsE" allowfullscreen allow="fullscreen" style="border: none;"></iframe></div></div>""")
	}

	private Str write(Str fandoc) {
		HtmlDocWriter.fullyLoaded.parseAndWriteToStr(fandoc).trimEnd
	}
}

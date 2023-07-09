
internal class TestHtml5VideoProcessor : FandocTest {
	
	Void testBasic() {
		out := write("![meh]`/video/catlolz.mp4`")
		verifyEq(out, """<div class="htmlVideo"><div class="el-frame" style="--el-frame-width:16; --el-frame-height:9"><video muted playsinline controls><source src="/video/catlolz.mp4" type="video/mp4"><p>Your browser does not support HTML5 video. Here is a <a href="/video/catlolz.mp4">link to the video</a> instead.</p></video></div></div>""")
	}

	Void testSize() {
		out := write("![meh][200x100]`/video/catlolz.webm`")
		verifyEq(out, """<div class="htmlVideo" style="width:200px; height:100px;"><div class="el-frame" style="--el-frame-width:16; --el-frame-height:9"><video muted playsinline controls><source src="/video/catlolz.webm" type="video/webm"><p>Your browser does not support HTML5 video. Here is a <a href="/video/catlolz.webm">link to the video</a> instead.</p></video></div></div>""")
	}

	Void testAspect() {
		out := write("![meh]`/video/catlolz.webm?aspectRatio=2x1`")
		verifyEq(out, """<div class="htmlVideo"><div class="el-frame" style="--el-frame-width:2; --el-frame-height:1"><video muted playsinline controls><source src="/video/catlolz.webm" type="video/webm"><p>Your browser does not support HTML5 video. Here is a <a href="/video/catlolz.webm">link to the video</a> instead.</p></video></div></div>""")
	}
}

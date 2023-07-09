
internal class TestVimeoProcessor : FandocTest {
	
	Void testBasic() {
		out := write("![meh]`https://vimeo.com/11712103`")
		verifyEq(out, """<div class="vimeoVideo"><div class="el-frame" style="--el-frame-width:16; --el-frame-height:9"><iframe src="https://player.vimeo.com/video/11712103" allowfullscreen allow="fullscreen" style="border: none;"></iframe></div></div>""")
	}
	
	Void testSize() {
		out := write("![meh][200x100]`https://vimeo.com/11712103`")
		verifyEq(out, """<div class="vimeoVideo" style="width:200px; height:100px;"><div class="el-frame" style="--el-frame-width:16; --el-frame-height:9"><iframe src="https://player.vimeo.com/video/11712103" allowfullscreen allow="fullscreen" style="border: none;"></iframe></div></div>""")
	}

	Void testAspect() {
		out := write("![meh]`https://vimeo.com/11712103?aspectRatio=2x1`")
		verifyEq(out, """<div class="vimeoVideo"><div class="el-frame" style="--el-frame-width:2; --el-frame-height:1"><iframe src="https://player.vimeo.com/video/11712103" allowfullscreen allow="fullscreen" style="border: none;"></iframe></div></div>""")
	}
}

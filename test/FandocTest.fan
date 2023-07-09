
internal abstract class FandocTest : Test {
	
	Str write(Str fandoc) {
		HtmlDocWriter.fullyLoaded.parseAndWriteToStr(fandoc).trim
	}	
}

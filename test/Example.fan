//using afFandoc::HtmlDocWriter

class Example {
	Void main() {
		fandoc := "..."

		html := HtmlDocWriter.fullyLoaded.parseAndWriteToStr(fandoc)

		echo(html)	// --> <html> ... </html>
	}
}

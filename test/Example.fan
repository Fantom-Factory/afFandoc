//using afFandoc::HtmlDocWriter

class Example {
	Void main() {
		fandoc := "..."

		html := HtmlWriter2.fullyLoaded.parseAndWriteToStr(fandoc)

		echo(html)	// --> <html> ... </html>
	}
}

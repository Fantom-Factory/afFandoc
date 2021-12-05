
internal class TestLinkResolvers : Test {
	
	Void testFantomLinkResolver() {
		linkResolver := FandocLinkResolver()
		url			 := null as Uri

		// pod::index         pod         absolute link to pod index
		// pod::pod-doc       pod         absolute link to pod doc chapter
		// pod::Type          Type        absolute link to type qname
		// pod::Types.slot    Type.slot   absolute link to slot qname
		// pod::Chapter       Chapter     absolute link to book chapter
		// pod::Chapter#frag  Chapter     absolute link to book chapter anchor

		url = linkResolver.resolve("sys", `sys::index`)
		verifyEq(url, `https://fantom.org/doc/sys/`)

		url = linkResolver.resolve("sys", `sys::pod-doc`)
		verifyEq(url, `https://fantom.org/doc/sys/`)

		url = linkResolver.resolve("sys", `sys::Type`)
		verifyEq(url, `https://fantom.org/doc/sys/Type`)

		url = linkResolver.resolve("sys", `sys::Type.slot`)
		verifyEq(url, `https://fantom.org/doc/sys/Type#slot`)

		url = linkResolver.resolve("docLang", `doclang::Methods`)
		verifyEq(url, `https://fantom.org/doc/docLang/Methods`)

		url = linkResolver.resolve("docLang", `docLang::Methods#this`)
		verifyEq(url, `https://fantom.org/doc/docLang/Methods#this`)
	}
	
	Void testPathAbsPassThrough() {
		linkResolver := LinkResolver.pathAbsPassThroughResolver
		url			 := null as Uri		

		url = linkResolver.resolve("http", `http://example.com`)
		verifyEq(url, null)

		url = linkResolver.resolve(null, `/doc/wotever`)
		verifyEq(url, `/doc/wotever`)

		url = linkResolver.resolve(null, `/doc/wotever#frag`)
		verifyEq(url, `/doc/wotever#frag`)

		url = linkResolver.resolve(null, `/doc/wotever?query`)
		verifyEq(url, `/doc/wotever?query`)
	}
}

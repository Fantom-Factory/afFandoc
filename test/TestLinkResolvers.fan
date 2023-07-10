
internal class TestLinkResolvers : Test {
	
	Void testFantomLinkResolver() {
		linkResolver := FandocLinkResolver()
		uri			 := null as Uri

		// pod::index         pod         absolute link to pod index
		// pod::pod-doc       pod         absolute link to pod doc chapter
		// pod::Type          Type        absolute link to type qname
		// pod::Types.slot    Type.slot   absolute link to slot qname
		// pod::Chapter       Chapter     absolute link to book chapter
		// pod::Chapter#frag  Chapter     absolute link to book chapter anchor

		uri = linkResolver.resolve("sys", `sys::index`)
		verifyEq(uri, `https://fantom.org/doc/sys/`)

		uri = linkResolver.resolve("sys", `sys::pod-doc`)
		verifyEq(uri, `https://fantom.org/doc/sys/`)

		uri = linkResolver.resolve("sys", `sys::Type`)
		verifyEq(uri, `https://fantom.org/doc/sys/Type`)

		uri = linkResolver.resolve("sys", `sys::Type.slot`)
		verifyEq(uri, `https://fantom.org/doc/sys/Type#slot`)

		uri = linkResolver.resolve("docLang", `doclang::Methods`)
		verifyEq(uri, `https://fantom.org/doc/docLang/Methods`)

		uri = linkResolver.resolve("docLang", `docLang::Methods#this`)
		verifyEq(uri, `https://fantom.org/doc/docLang/Methods#this`)
	}
	
	Void testPathAbsPassThrough() {
		linkResolver := LinkResolver.pathAbsPassThroughResolver
		uri			 := null as Uri		

		uri = linkResolver.resolve("http", `http://example.com`)
		verifyEq(uri, null)

		uri = linkResolver.resolve(null, `/doc/wotever`)
		verifyEq(uri, `/doc/wotever`)

		uri = linkResolver.resolve(null, `/doc/wotever#frag`)
		verifyEq(uri, `/doc/wotever#frag`)

		uri = linkResolver.resolve(null, `/doc/wotever?query`)
		verifyEq(uri, `/doc/wotever?query`)
	}
}

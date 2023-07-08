using fandoc::DocElem
using fandoc::DocWriter
using fandoc::FandocParser

** A 'PreProcessor' for rendering tables to HTML.
@Js
class TableProcessor : PreProcessor {	
	private TableParser tableParser		:= TableParser()

	** Hook for rendering cell text. Just returns 'text.toXml' by default.
	|Str->Str|?	renderHtmlFn
	
	@NoDoc
	override Obj? process(HtmlElem elem, DocElem src, Uri cmd, Str preText) {
		table := HtmlElem("table").addText(cmd.pathStr.trimStart)
		CssPrefixProcessor().process(table, src)
		table.removeAllChildren
		
		rows  := tableParser.parseTable(preText.splitLines)
		thead := HtmlElem("thead") {
			HtmlElem("tr").with |tr| {
				rows.first.each |th| {
					tr.add( HtmlElem("th") {
						it.addHtml(toHtml(th))
					})
				}
			},
		}
		tbody := HtmlElem("tbody").with |tbody| {
			rows.eachRange(1..-1) |row| {
				tbody.add(HtmlElem("tr").with |tr| {
					row.each |td| {
						tr.add( HtmlElem("td") {
							it.addHtml(toHtml(td))
						})
					}
				})
			}
		}
		
		if (rows.first.size > 0)
			table.add(thead)
		table.add(tbody)

		return table
	}
	
	private Str toHtml(Str text) {
		renderHtmlFn?.call(text) ?: text.toXml
	}
}

** Parses table text into a 2D array of strings.
@Js
const class TableParser {

	** Parses the table text.
	Str[][] parseTable(Str[] lines) {
		ctrl := (Str) (lines.find { it.trim.startsWith("-") } ?: throw ParseErr("Could not find table syntax in:\n" + lines.join("\n")))
		
		// find the ranges of the ---'s
		colRanges := Range[,]
		last := 0
		while (last < ctrl.size && ctrl.index("-", last) != null) {
			start := ctrl.index("-", last)
			end := start
			while (end < ctrl.size && ctrl[end] == '-') end++
			dashes := ctrl[start..<end]
			if (!dashes.trim.isEmpty)
				colRanges.add(start..<end)
			last = end
		}
		
		// extend the ranges to the start of the next - dash
		colRanges = colRanges.map |col, i -> Range| {
			next := colRanges.getSafe(i+1)
			end  := next == null ? Int.maxVal : next.start - 1
			return col.start..<end
		}

		inHeader := true
		headers  := Str[,]
		rows	 := Str[][,]
		lines.each |line| {
			if (line.trim.isEmpty)
				return

			if (inHeader) {
				if (line.trim.startsWith("-")) {
					inHeader = false
					return
				}
				colRanges.each |col, i| {
					header := getTableData(line, col)
					if (header != null)
						if (i < headers.size)
							headers[i] = "${headers[i]} ${header}".trim
						else
							headers.add(header)
				}
			} else {
				row := Str[,]
				colRanges.each |col| {
					data := getTableData(line, col)
					if (data != null)
						row.add(data)
				}
				if (!row.isEmpty)
					rows.add(row)
			}
		}

		return rows.insert(0, headers)
	}

	private Str? getTableData(Str line, Range col) {
		data := (Str?) Str.defVal
		if (col.start < line.size)
			if (col.end < line.size)
				data = line.getRange(col).trim
			else
				data = line.getRange(col.start..-1).trim
		
		if (data.isEmpty)
			return data

		// special case for fancy tables - needed for the last column where we grab all we can
		if (!data.isEmpty && data[-1] == '|')
			data = data[0..<-1].trim
		
		return data.chars.all { it == '-' || it == '=' || it == '|' || it == '+' || it.isSpace } ? null : data
	}
}

using fandoc::DocElem
using fandoc::DocWriter
using fandoc::FandocParser

** A 'PreProcessor' for rendering tables to HTML.
@Js
class TableProcessor : PreProcessor {	
	private TableParser tableParser		:= TableParser()

	** Hook for rendering cell text. Just returns 'text.toXml' by default.
	|Str->Str|	textRenderer	:= |Str text->Str| { text.toXml }
	Str 		table			:= "<table>"
	Str 		tableEnd		:= "</table>"
	Str 		thead			:= "<thead>"
	Str			theadEnd		:= "</thead>"
	Str			tbody			:= "<tbody>"
	Str			tbodyEnd		:= "</tbody>"
	Str			tr				:= "<tr>"
	Str			trEnd			:= "</tr>"
	Str			th				:= "<th>"
	Str			thEnd			:= "</th>"
	Str			td				:= "<td>"
	Str			tdEnd			:= "</td>"
	
	@NoDoc
	override Obj? process(HtmlElem elem, DocElem src, Uri cmd, Str preText) {
		rows := tableParser.parseTable(preText.splitLines)
		str	 := StrBuf()
		out	 := str.out

		out.print(table)
		if (!rows.first.isEmpty) {
			out.print(thead)
			out.print(tr)
			rows.first.each { 
				out.print(th)
				out.print(textRenderer(it))
				out.print(thEnd)
			}
			out.print(trEnd)
			out.print(theadEnd)
		}
		
		out.print(tbody)
		rows.eachRange(1..-1) |row| {
			out.print(tr)
			row.each { 
				out.print(td)
				out.print(textRenderer(it))
				out.print(tdEnd)
			}
			out.print(trEnd)
		}
		out.print(tbodyEnd)
		out.print(tableEnd)

		return str.toStr
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

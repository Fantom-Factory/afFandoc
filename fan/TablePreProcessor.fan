using fandoc::DocElem
using fandoc::DocWriter
using fandoc::FandocParser

@Js
class TablePreProcessor : PreTextProcessor {	
	private TableParser tableParser		:= TableParser()

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
	
	override Void process(OutStream out, DocElem elem, Uri cmd, Str preText) {
		rows := tableParser.parseTable(preText.splitLines)

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
	}
}

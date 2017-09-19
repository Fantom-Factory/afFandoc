
class TestTableParsing : Test {
	
	Void testSimpleTable() {
		
		table := 
"""

        Dual
      Full Name    First Name  Last Name
     ------------  ----------- ----------
      John Smith   John        Smith
      Steve Eynon  Steve       Eynon

      Fred Bloggs  Fred        Bloggs
   """
		data := TableParser().parseTable(table.splitLines)
		verifyTable(data)

		
		
		table2 :=
"""
     +-------------+-------+---------+
     | Dual        | First | Last    |
     | Full Name   | Name  | Name    |
      -------------+-------+---------+
     | John Smith  | John  | Smith   |
     | Steve Eynon | Steve | Eynon   |
     | Fred Bloggs | Fred  | Bloggs  |
     +- - - - - - -+- - - -+- - - - -+
   """
		data2 := TableParser().parseTable(table2.splitLines)
		verifyTable(data2)

		
		
		// this syntax is because I keep forgetting to --- all the way across on the last line
		// I may as well condence it too!
		table3 :=
"""
        Dual      First Last
      Full Name   Name  Name
     -            -     -
      John Smith  John  Smith
      Steve Eynon Steve Eynon
      Fred Bloggs Fred  Bloggs
   """
		data3 := TableParser().parseTable(table3.splitLines)
		verifyTable(data3)
		
		
		// BugFix - Allow blanks in table
		table4 :=
"""
      Full Name   Name  Name
     -            -     -
                  John  Smith
      Steve Eynon       Eynon
      Fred Bloggs Fred        
   """
		data4 := TableParser().parseTable(table4.splitLines)
		verifyEq(data4[1][0], "")
		verifyEq(data4[1][1], "John")
		verifyEq(data4[1][2], "Smith")
		
		verifyEq(data4[2][0], "Steve Eynon")
		verifyEq(data4[2][1], "")
		verifyEq(data4[2][2], "Eynon")
		
		verifyEq(data4[3][0], "Fred Bloggs")
		verifyEq(data4[3][1], "Fred")
		verifyEq(data4[3][2], "")
		
		
		table5 := 
"""
      Key      Name
     -------  -------------
      Bruce    batWings 0+
   """
		data5 := TableParser().parseTable(table5.splitLines)
		verifyEq(data5[1][0], "Bruce")
		verifyEq(data5[1][1], "batWings 0+")
	}
	
	private Void verifyTable(Str[][] data) {
		verifyEq(data[0][0], "Dual Full Name")
		verifyEq(data[0][1], "First Name")
		verifyEq(data[0][2], "Last Name")
		
		verifyEq(data[1][0], "John Smith")
		verifyEq(data[1][1], "John")
		verifyEq(data[1][2], "Smith")
		
		verifyEq(data[2][0], "Steve Eynon")
		verifyEq(data[2][1], "Steve")
		verifyEq(data[2][2], "Eynon")
		
		verifyEq(data[3][0], "Fred Bloggs")
		verifyEq(data[3][1], "Fred")
		verifyEq(data[3][2], "Bloggs")

		verifyEq(data.size, 4)
	}
	
}

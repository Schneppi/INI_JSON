#tag Class
Protected Class INI_JSON
	#tag Method, Flags = &h0
		Sub Constructor()
		  
		  INI_JSON_ = New JSONItem("{}")
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Constructor(file As FolderItem)
		  
		  LoadINI(file)
		  
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Constructor(filepath As String)
		  
		  LoadINI(New FolderItem(filepath))
		  
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub CreateSession(session As String)
		  // Create a session if needed
		  
		  session = session.Trim
		  
		  If Not INI_JSON_.HasKey(session) Then
		    INI_JSON_.Value(session) = New JSONItem("{}") // Create an empty one if none exists
		  End
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub LoadINI(file As FolderItem)
		  If file = Nil Or file.IsFolder Then
		    Raise New RuntimeException("Invalid INI file", 1)
		  End
		  
		  Var ini As New JSONItem("{}") // Empty INI, no sections, thus no properties
		  
		  If Not file.Exists Then
		    INI_JSON_ = ini
		    Return // Empty JSON INI
		  End
		  
		  Var read As TextInputStream = TextInputStream.Open(file)
		  
		  Var numLine As Integer = 0
		  
		  Var line, session As String
		  
		  // Locate session
		  Do Until read.EndOfFile
		    line = read.ReadLine.Trim
		    numLine = NumLine + 1
		    If line="" Then Continue // skip
		    If line.Left(1)=";" Or line.Left(1)="#" Or line.Left(2)="//" Then Continue // Skip comments
		    // Found something, must be initial section
		    If line.Length>2 And line.Left(1)<>"[" Or line.Right(1)<>"]" Then // Missing Initial section
		      Raise New RuntimeException("Missing Section at line #"+numLine.ToString, 1)
		    End
		    session = line.Middle(1, line.Length -2).Trim
		    exit
		  Loop
		  
		  If session = "" Then 
		    INI_JSON_ = ini
		    Return // Empty INI, no sections, thus no properties
		  End
		  
		  Var properties As New JSONItem("{}") // Create empty set of properties
		  
		  ini.Value(session) = properties // Start session
		  
		  line = ""
		  
		  // Load properties and more sessions
		  Do Until read.EndOfFile
		    line = read.ReadLine.Trim
		    numLine = NumLine + 1
		    If line="" Then Continue // skip
		    If line.Left(1)=";" Or line.Left(1)="#" Or line.Left(2)="//" Then Continue // Skip comments
		    // Found something, check if session or property
		    If line.Length>2 And line.Left(1)="[" Or line.Right(1)="]" Then // section
		      session = line.Middle(1, line.Length -2).Trim // change session
		      properties = ini.Lookup(session, New JSONItem("{}")) // Merge or create new properties
		      ini.Value(session) = properties // Start session
		    ElseIf line.IndexOf("=")>0 Then // property
		      Var pos As Integer= line.IndexOf("=")
		      Var name, value As String
		      name = line.Left(pos).Trim
		      If name="" Then
		        Var slice As String = " ❮"+line.Left(10)+If(line.Length>10, "…❯", "❯")
		        Raise New RuntimeException("Syntax error at line #"+numLine.ToString+slice, 1)
		      End
		      If pos+1<line.Length Then value = line.Middle(pos+1).Trim
		      properties.Value(name) = value // Set property
		    Else // garbage
		      Var slice As String = " ❮"+line.Left(10)+If(line.Length>10, "…❯", "❯")
		      Raise New RuntimeException("Syntax error at line #"+numLine.ToString+slice, 1)
		    End
		    
		  Loop
		  
		  INI_JSON_ = ini // load
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub LoadJSON(file As FolderItem)
		  If file = Nil Or file.IsFolder Then
		    Raise New RuntimeException("Invalid JSON file", 1)
		  End
		  
		  Var t As TextInputStream = TextInputStream.Open(file)
		  INI_JSON_ = New JSONItem(t.ReadAll)
		  t.Close
		  
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function Lookup(session As String, prop As String, default As Variant = Nil) As Variant
		  // Var ini As New INI_JSON(New FolderItem("D:\data\file.INI"))
		  // Var pararm As String = ini.Lookup("SESSION1", "color") // get "blue"
		  //
		  // file.INI example:
		  //
		  // [SESSION0]
		  // p = 0
		  //
		  // [SESSION1]
		  // color = blue
		  
		  session = session.Trim
		  prop = prop.Trim
		  
		  // Look into the session for a property and return its value, if not found return default
		  Var properties As JSONItem = INI_JSON_.Lookup(session, New JSONItem("{}"))
		  Return properties.Lookup(prop, default)
		  
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Function PropertyExists(session As String, prop As String) As Boolean
		  // Return True if a property existis in a session
		  
		  session = session.Trim
		  
		  If INI_JSON_.HasKey(session) Then
		    Var properties As JSONItem = INI_JSON_.Value(session)
		    Return properties.HasKey(prop.Trim)
		  End
		  Return False // Not even that session exists
		  
		  
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub RemoveProperty(session As String, prop As String)
		  // Remove a property from a session
		  
		  
		  session = session.Trim
		  prop = prop.Trim
		  #Pragma BreakOnExceptions False
		  Try
		    Var properties As JSONItem = INI_JSON_.Value(session)
		    properties.Remove(prop)
		    INI_JSON_.Value(session) = properties
		  Catch // Ignore non-existent property in a session
		  End
		  #Pragma BreakOnExceptions Default
		  
		  
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub RemoveSession(session As String)
		  // Remove a session
		  
		  #Pragma BreakOnExceptions False
		  Try
		    INI_JSON_.Remove(session.Trim)
		  Catch // Ignore if not found
		  End
		  #Pragma BreakOnExceptions False
		  
		  
		  
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub SaveINI(file As FolderItem, remarks As String = "")
		  // Save the INI file, add multiline remarks on top (breaks on semicolons)
		  
		  If file = Nil Or file.IsFolder Then
		    Raise New RuntimeException("Invalid target INI file", 1)
		  End
		  
		  Var inifile As TextOutputStream = TextOutputStream.Create(file)
		  
		  // You can put remarks on top of the INI file
		  If remarks > "" Then
		    
		    Var remLine() As String = remarks.Split(";") // semicolons splits lines
		    
		    For each line As String in remLine
		      inifile.WriteLine("; "+line)
		    Next
		    
		  End
		  
		  For each session As String in INI_JSON_.Keys
		    inifile.WriteLine("")
		    inifile.WriteLine("["+session+"]")
		    inifile.WriteLine("")
		    
		    Var props As JSONItem = INI_JSON_.Value(session)
		    
		    For each key As String in props.Keys
		      inifile.WriteLine(key + "=" + props.Value(key))
		    Next
		    
		  Next
		  
		  inifile.Close
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub SaveJSON(file As FolderItem)
		  // Save the INI as a JSON file equivalent
		  
		  If file = Nil Or file.IsFolder Then
		    Raise New RuntimeException("Invalid target JSON file", 1)
		  End
		  
		  Var t As TextOutputStream = TextOutputStream.Create(file)
		  t.WriteLine(INI_JSON_.ToString)
		  t.Close
		  
		End Sub
	#tag EndMethod

	#tag Method, Flags = &h0
		Function SessionExists(session As String) As Boolean
		  // Return True if a session exists
		  
		  Return INI_JSON_.HasKey(session.Trim)
		  
		  
		  
		  
		End Function
	#tag EndMethod

	#tag Method, Flags = &h0
		Sub Set(session As String, prop As String, propValue As Variant)
		  // Set a property in a session to a value
		  // It creates sessions if one does not exists
		  
		  session = session.Trim
		  prop = prop.Trim
		  Var properties As JSONItem = INI_JSON_.Lookup(session, New JSONItem("{}"))
		  properties.Value(prop) = propValue
		  INI_JSON_.Value(session) = properties
		  
		  
		  
		End Sub
	#tag EndMethod


	#tag Note, Name = Copyright
		
		Rick A. - 2023 (copyleft, just remember me and use as you wish)
		
		v.1.0 - Load INI, Saves as JSON, can load such JSON back, can lookup and set session properties
		v.1.1 - Added SaveINI
		v.1.2 - Enhanced the example. Adjust the code for your use, catch exceptions as needed
		v.1.3 - Covered more use cases, Added: 
		        SessionExists(), PropertyExists(), RemoveSession(), RemoveProperty(), CreateSession()
		
		
		INI used in the tests:
		
		https://raw.githubusercontent.com/stevemarple/IniFile/master/examples/IniFileExample/net.ini
		
	#tag EndNote


	#tag Property, Flags = &h21
		Private INI_JSON_ As JSONItem
	#tag EndProperty


	#tag ViewBehavior
		#tag ViewProperty
			Name="Name"
			Visible=true
			Group="ID"
			InitialValue=""
			Type="String"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="Index"
			Visible=true
			Group="ID"
			InitialValue="-2147483648"
			Type="Integer"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="Super"
			Visible=true
			Group="ID"
			InitialValue=""
			Type="String"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="Left"
			Visible=true
			Group="Position"
			InitialValue="0"
			Type="Integer"
			EditorType=""
		#tag EndViewProperty
		#tag ViewProperty
			Name="Top"
			Visible=true
			Group="Position"
			InitialValue="0"
			Type="Integer"
			EditorType=""
		#tag EndViewProperty
	#tag EndViewBehavior
End Class
#tag EndClass

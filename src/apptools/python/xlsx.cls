/// d ##class(apptools.python.xlsx).test()
Class apptools.python.xlsx
{

Parameter DATADIRECTORY = "/home/irisowner/dev/data/";

/// d ##class(apptools.python.xlsx).test()
ClassMethod test() As %Status
{
 set sql="select * FROM dc_demo.titanic"
#;  set sql="select name,sex,age FROM dc_demo.titanic"
 set gn="^||tmp",format=",n,n,n,n,s5,s5,s40,s5,s50" 
 set format("freeze")="B3" ;freeze
 set format("title")="Title "_sql
 set format("sheetname")="test"
#;  do ##class(apptools.core.sys).SaveSQL(sql,gn)
 set exec="##class(apptools.python.xlsx).MarkRed(.%AppLogInfoVal, .%AppLogInfoCol, .%AppLogInfoHead, .%AppLogInfoTemp)"
#;  do ##class(apptools.python.xlsx).gn2xlsx(gn,.format,..#DATADIRECTORY_"___gn2xlsx*.xlsx","Title "_sql,,,,exec)
 set format("freeze")="B4" ;freeze
 do ##class(apptools.python.xlsx).sql2xlsx(sql,.format,..#DATADIRECTORY_"sql2xlsx*.xlsx")
 quit $$$OK
}

ClassMethod sql2xlsx(sql, format = "", file As %String = "/home/irisowner/dev/data/sample-py-*.xlsx", title = "")
{
	set st=$$$OK
	set statement = ##CLASS(%SQL.Statement).%New()
	set status=statement.%Prepare(sql)
	if $$$ISERR(status) {write "%Prepare failed:" do $SYSTEM.Status.DisplayError(status) quit}

	set rset=statement.%Execute()
	if (rset.%SQLCODE '= 0) {write "%Execute failed:", !, "SQLCODE ", rset.%SQLCODE, ": ", rset.%Message quit}

	;prepare XLSX
	try {
        set openpyxl = ##class(%SYS.Python).Import("openpyxl") 
    } catch err {
        do ..InstallPy("openpyxl")
        set openpyxl = ##class(%SYS.Python).Import("openpyxl") 
    }
	set wb = openpyxl.Workbook()
	#; grab the active worksheet
	set ws = wb.active
	set ws.title = $select($D(format("sheetname"),ds):ds,1:"sheetname")
	set pybuiltins = $system.Python.Import("builtins")
	set pycols = pybuiltins.list()
	do pycols.append(" ")
	do ws.append(pycols)

	set pycols = pybuiltins.list()
	set (count)=0
	set ColCount=statement.%Metadata.columns.Count()
	for i=1:1:ColCount {	
		do pycols.append(statement.%Metadata.columns.GetAt(i).colName)
		set col=openpyxl.utils."get_column_letter"(i)
	}
	do ws.append(pycols)

	while (rset.%Next())	{
		set count=count+1
		set pyrows = pybuiltins.list()
		for ii=1:1:ColCount {
			set val=..CleanCtrl(rset.%GetData(ii))
			if $e($P(format,",",ii),1)="d" { //date
				set val=..ToPyDate(val)
			}
			elseif $e($P(format,",",ii),1,2)="dt" { //datetime
				set val=..ToPyDateTime(val)
			}
			elseif $e($P(format,",",ii),1)="n" { //number
				set val=+val
			}
			do pyrows.append(val)
		}
		do ws.append(pyrows)
	}
   ;}
   	if $g(format("freeze"))'="" {
		; set builtins = $system.Python.Import("builtins") zwrite builtins.type(ws)  zwrite builtins.dir(wb)
		set ws."freeze_panes" = pybuiltins.str(format("freeze")) ;format("freeze")
		;set ws."freeze_panes" = "B2" ;format("freeze")
	}
	else {
		set ws."freeze_panes" = pybuiltins.str("B2") ;default
	}
	if file["*" set file=$replace(file,"*","-"_$zd($h,3)_"_"_$tr($zt($p($h,",",2),1),":"))
	write !,"Save into "_file_" rows: "_count
	do wb.save(file)
	q $GET(count)
}

/// set gn="^||tmp",format="n,s150,,,,,,,,d," 
/// set format("freeze")="B5" ;freeze
/// d ##class(apptools.core.sys).SaveSQL("select * from apptools_core.Log order by id desc",gn)
/// d ##class(apptools.python.xlsx).gn2xlsx(gn,.format,"/iris-backup/temp/test*.xlsx","Test")
/// Example coloring a column values if is not null
///  set exec="##class(apptools.python.xlsx).MarkRed(.%AppLogInfoVal, %AppLogInfoCol, %AppLogInfoHead, .%AppLogInfoTemp)"
ClassMethod MarkRed(Val, Col, Head, openpyxl)
{
	s res=Val
	if $g(Head) {
		if res.value="DispatchClass" set Col("DispatchClass",Col)=""
	}
	else {
		if $Data(Col("DispatchClass",Col)) {
			if res.value'="" {
				;set argsfill = {"start_color":"D3D3D3", "end_color":"D3D3D3", "fill_type":"solid"}
    			;set fill = openpyxl.styles.PatternFill(argsfill...)	
				set argsfont = {"color":"DC143C", "bold":true, "italic":false, "size":11} ;color Crimson
				set font = openpyxl.styles.Font(argsfont...)
				;set res.value=$FN(res.value,"",2)
				;set res.fill=fill
				set res.font=font
			}
		}
	}
	q res
}

/// do ##class(apptools.python.xlsx).InstallPy("openpyxl")
ClassMethod InstallPy(lib)
{
    //  depricated  ;set sc = ##class(%SYS.Python).Install("openpyxl")
    set cmd="pip3 install --target /usr/irissys/mgr/python/ "_lib
    if $zversion(1)'=3 {
        set tMgrDir = $System.Util.ManagerDirectory()
		set tBinDir = $System.Util.BinaryDirectory()_"irispip.exe"
		set cmd=tBinDir_" install --target "_tMgrDir_"python "_lib
    }
    set st=##class(%ZPM.PackageManager.Developer.Utils).RunCommandViaZF(cmd,.tLog,.tErr)
    quit $$$OK
}

/// Date YYYY-MM-DD HH:MM:SS to Python dt.datetime
ClassMethod ToPyDateTime(val, ByRef dt)
{
	quit:'val val
	if val["." set val=$p(val,".",3)_"-"_$p(val,".",2)_"-"_$p(val,".",1) // format YYYY-MM-DD
	if val'["-" set val=$zd(+val,3) // $h format
	set dt = ##class(%SYS.Python).Import("datetime")
	set val=dt.datetime(+$p(val,"-",1), +$p(val,"-",2), +$p($p(val,"-",3)," "),+$p($p(val,":",1)," ",2),+$p($p(val,":",2)," ",2),+$p($p(val,":",3)," ",2))
	quit val
}

/// Date YYYY-MM-DD to Python dt.date
ClassMethod ToPyDate(val, ByRef dt)
{
	quit:'val val
	if val["." set val=$p(val,".",3)_"-"_$p(val,".",2)_"-"_$p(val,".",1) // format YYYY-MM-DD
	if val'["-" w 111_val_111 set val=$zd(+val,3) // $h format
	set dt = ##class(%SYS.Python).Import("datetime")
	set val=dt.date(+$p(val,"-",1), +$p(val,"-",2), +$p($p(val,"-",3)," "))
	quit val
}

ClassMethod CleanCtrl(val)
{
	quit $zstrip(val,"*C")
}

}

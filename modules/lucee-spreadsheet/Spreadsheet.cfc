component accessors="true"{

	//"static"
	property name="version" default="2.21.0" setter="false";
	property name="osgiLibBundleVersion" default="5.0.0.2" setter="false"; //first 3 octets = POI version; increment 4th with other jar updates
	property name="osgiLibBundleSymbolicName" default="luceeSpreadsheet" setter="false";
	property name="exceptionType" default="cfsimplicity.lucee.spreadsheet" setter="false";
	//commonly invoked POI class names
	property name="HSSFWorkbookClassName" default="org.apache.poi.hssf.usermodel.HSSFWorkbook" setter="false";
	property name="XSSFWorkbookClassName" default="org.apache.poi.xssf.usermodel.XSSFWorkbook" setter="false";
	property name="SXSSFWorkbookClassName" default="org.apache.poi.xssf.streaming.SXSSFWorkbook" setter="false";
	//configurable
	property name="dateFormats" type="struct";
	property name="javaLoaderDotPath" default="javaLoader.JavaLoader";
	property name="javaLoaderName" default="";
	property name="requiresJavaLoader" type="boolean" default="false";
	//detected state
	property name="isACF" type="boolean";
	property name="javaClassesLastLoadedVia" default="Nothing loaded yet";
	//cached POI helper objects
	property name="cellUtil" getter="false" setter="false";
	property name="dateUtil" getter="false" setter="false";
	property name="dataFormatter" getter="false" setter="false";
	//Lucee osgi loader
	property name="osgiLoader";

	function init( struct dateFormats, string javaLoaderDotPath, boolean requiresJavaLoader ){
		detectEngineProperties();
		this.setDateFormats( defaultDateFormats() );
		if( arguments.KeyExists( "dateFormats" ) )
			overrideDefaultDateFormats( arguments.dateFormats );
		this.setRequiresJavaLoader( this.getIsACF() || ( arguments.KeyExists( "requiresJavaLoader" ) && arguments.requiresJavaLoader ) );
		if( !this.getRequiresJavaLoader() ){
			this.setOsgiLoader( New osgiLoader() );
			return this;
		}
		this.setJavaLoaderName( "spreadsheetLibraryClassLoader-#this.getVersion()#-#Hash( GetCurrentTemplatePath() )#" );
		 // Option to use the dot path of an existing javaloader installation to save duplication
		if( arguments.KeyExists( "javaLoaderDotPath" ) )
			this.setJavaLoaderDotPath( arguments.javaLoaderDotPath );
		return this;
	}

	/* Meta utilities */
	private struct function defaultDateFormats(){
		return {
			DATE: "yyyy-mm-dd"
			,DATETIME: "yyyy-mm-dd HH:nn:ss"
			,TIME: "hh:mm:ss"
			,TIMESTAMP: "yyyy-mm-dd hh:mm:ss"
		};
	}

	private void function overrideDefaultDateFormats( required struct formats ){
		for( var format in arguments.formats ){
			if( !this.getDateFormats().KeyExists( format ) )
				Throw( type=this.getExceptionType(), message="Invalid date format key", detail="'#format#' is not a valid dateformat key. Valid keys are DATE, DATETIME, TIME and TIMESTAMP" );
			variables.dateFormats[ format ] = arguments.formats[ format ];
		}
	}

	private void function detectEngineProperties(){
		this.setIsACF( ( server.coldfusion.productname == "ColdFusion Server" ) );
	}

	public string function getPoiVersion(){
		return loadClass( "org.apache.poi.Version" ).getVersion();
	}

	public void function flushPoiLoader(){
		lock scope="server" timeout="10" {
			StructDelete( server, this.getJavaLoaderName() );
		};
	}

	public void function flushOsgiBundle(){
		this.getOsgiLoader().uninstallBundle( this.getOsgiLibBundleSymbolicName(), this.getOsgiLibBundleVersion() );
	}

	public struct function getEnvironment(){
		return {
			dateFormats: this.getDateFormats()
			,engine: server.coldfusion.productname & " " & ( this.getIsACF()? server.coldfusion.productversion: ( server.lucee.version?: "?" ) )
			,javaLoaderDotPath: this.getJavaLoaderDotPath()
			,javaClassesLastLoadedVia: this.getJavaClassesLastLoadedVia()
			,javaLoaderName: this.getJavaLoaderName()
			,requiresJavaLoader: this.getRequiresJavaLoader()
			,version: this.getVersion()
			,poiVersion: this.getPoiVersion()
			,osgiLibBundleVersion: this.getOsgiLibBundleVersion()
		};
	}

	/* Diagnostic tools */

	/* check physical path of a specific class */
	public void function dumpPathToClass( required string className ){
		if( IsNull( this.getOsgiLoader() ) )
			return dumpPathToClassNoOsgi( arguments.className );
		var bundle = this.getOsgiLoader().getBundle( this.getOsgiLibBundleSymbolicName(), this.getOsgiLibBundleVersion() );
		var poi = loadClass( "org.apache.poi.Version" );
		var path = BundleInfo( poi ).location & "!" &  bundle.getResource( arguments.className.Replace( ".", "/", "all" ) & ".class" ).getPath();
		WriteDump( path );
	}

	public numeric function getWorkbookCellStylesTotal( required workbook ){
		return arguments.workbook.getNumCellStyles(); // limit is 4K xls/64K xlsx
	}

	/* MAIN PUBLIC API */

	/* Convenenience */

	public binary function binaryFromQuery(
		required query data
		,boolean addHeaderRow=true
		,boolean boldHeaderRow=true
		,boolean xmlFormat=false
		,boolean streamingXml=false
		,numeric streamingWindowSize=100
		,boolean ignoreQueryColumnDataTypes=false
		,struct datatypes
	){
		var workbook = workbookFromQuery( argumentCollection=arguments );
		var binary = readBinary( workbook );
		cleanUpStreamingXml( workbook );
		return binary;
	}

	public query function csvToQuery(
		string csv=""
		,string filepath=""
		,boolean firstRowIsHeader=false
		,boolean trim=true
		,string delimiter
		,array queryColumnNames
		,any queryColumnTypes="" //'auto', single default type e.g. 'VARCHAR', or list of types, or struct of column names/types mapping. Empty means no types are specified.
		,boolean makeColumnNamesSafe=false
	){
		var csvIsString = arguments.csv.Len();
		var csvIsFile = arguments.filepath.Len();
		if( !csvIsString && !csvIsFile )
			Throw( type=this.getExceptionType(), message="Missing required argument", detail="Please provide either a csv string (csv), or the path of a file containing one (filepath)." );
		if( csvIsString && csvIsFile )
			Throw( type=this.getExceptionType(), message="Mutually exclusive arguments: 'csv' and 'filepath'", detail="Only one of either 'filepath' or 'csv' arguments may be provided." );
		if(	csvIsFile ){
			throwErrorIFfileNotExists( arguments.filepath );
			throwErrorIFnotCsvOrTextFile( arguments.filepath );
			arguments.csv = FileRead( arguments.filepath );
		}
		if( IsStruct( arguments.queryColumnTypes ) && !arguments.firstRowIsHeader && !arguments.KeyExists( "queryColumnNames" )  )
			Throw( type=this.getExceptionType(), message="Invalid argument 'queryColumnTypes'.", detail="When specifying 'queryColumnTypes' as a struct you must also set the 'firstRowIsHeader' argument to true OR provide 'queryColumnNames'" );
		if( arguments.trim )
			arguments.csv = arguments.csv.Trim();
		if( arguments.KeyExists( "delimiter" ) )
			var format = getCsvFormatForDelimiter( arguments.delimiter );
		else
			var format = loadClass( "org.apache.commons.csv.CSVFormat" )[ JavaCast( "string", "RFC4180" ) ].withIgnoreSurroundingSpaces();
		var parsed = loadClass( "org.apache.commons.csv.CSVParser" ).parse( arguments.csv, format );
		var records = parsed.getRecords();
		var data = [];
		var maxColumnCount = 0;
		for( var record in records ){
			var row = [];
			var columnNumber = 0;
			var iterator = record.iterator();
			while( iterator.hasNext() ){
				columnNumber++;
				maxColumnCount = Max( maxColumnCount, columnNumber );
				row.Append( iterator.next() );
			}
			data.Append( row );
		}
		if( arguments.KeyExists( "queryColumnNames" ) && arguments.queryColumnNames.Len() )
			var columnNames = arguments.queryColumnNames;
		else{
			var columnNames = [];
			if( arguments.firstRowIsHeader )
				var headerRow = data[ 1 ];
			for( var i=1; i <= maxColumnCount; i++ ){
				if( arguments.firstRowIsHeader && !IsNull( headerRow[ i ] ) && headerRow[ i ].Len() ){
					columnNames.Append( headerRow[ i ] );
					continue;
				}
				columnNames.Append( "column#i#" );
			}
			if( arguments.firstRowIsHeader )
				data.DeleteAt( 1 );
		}
		arguments.queryColumnTypes = parseQueryColumnTypesArgument( arguments.queryColumnTypes, columnNames, maxColumnCount, data );
		return _QueryNew( columnNames, arguments.queryColumnTypes, data, arguments.makeColumnNamesSafe );
	}

	public void function download( required workbook, required string filename, string contentType ){
		var safeFilename = filenameSafe( arguments.filename );
		var filenameWithoutExtension = safeFilename.REReplace( "\.xlsx?$", "" );
		var extension = isXmlFormat( arguments.workbook )? "xlsx": "xls";
		arguments.filename = filenameWithoutExtension & "." & extension;
		var binary = readBinary( arguments.workbook );
		cleanUpStreamingXml( arguments.workbook );
		if( !arguments.KeyExists( "contentType" ) )
			arguments.contentType = isXmlFormat( arguments.workbook )? "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet": "application/msexcel";
		downloadBinaryVariable( binary, arguments.filename, arguments.contentType );
	}

	public void function downloadFileFromQuery(
		required query data
		,required string filename
		,boolean addHeaderRow=true
		,boolean boldHeaderRow=true
		,boolean xmlFormat=false
		,string contentType
		,boolean streamingXml=false
		,numeric streamingWindowSize=100
		,boolean ignoreQueryColumnDataTypes=false
		,struct datatypes
	){
		var safeFilename = filenameSafe( arguments.filename );
		var filenameWithoutExtension = safeFilename.REReplace( "\.xlsx?$","" );
		var extension = ( arguments.xmlFormat || arguments.streamingXml )? "xlsx": "xls";
		arguments.filename = filenameWithoutExtension & "." & extension;
		var binaryFromQueryArgs = {
			data: arguments.data
			,addHeaderRow: arguments.addHeaderRow
			,boldHeaderRow: arguments.boldHeaderRow
			,xmlFormat: arguments.xmlFormat
			,streamingXml: arguments.streamingXml
			,streamingWindowSize: arguments.streamingWindowSize
			,ignoreQueryColumnDataTypes: arguments.ignoreQueryColumnDataTypes
		};
		if( arguments.KeyExists( "datatypes" ) )
			binaryFromQueryArgs.datatypes = arguments.datatypes;
		var binary = binaryFromQuery( argumentCollection=binaryFromQueryArgs );
		if( !arguments.KeyExists( "contentType" ) )
			arguments.contentType = arguments.xmlFormat? "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet": "application/msexcel";
		downloadBinaryVariable( binary, arguments.filename, arguments.contentType );
	}

	public void function downloadCsvFromFile(
		required string src
		,required string filename
		,string contentType="text/csv"
		,string columns
		,string columnNames
		,numeric headerRow
		,string rows
		,string sheetName
		,numeric sheetNumber // 1-based
		,boolean includeHeaderRow=false
		,boolean includeBlankRows=false
		,boolean fillMergedCellsWithVisibleValue=false
		,string delimiter=","
	){
		arguments.format = "csv";
		arguments.csvDelimiter = arguments.delimiter;
		var csv = read( argumentCollection=arguments );
		var binary = ToBinary( ToBase64( csv.Trim() ) );
		var safeFilename = filenameSafe( arguments.filename );
		var filenameWithoutExtension = safeFilename.REReplace( "\.csv$","" );
		var extension = "csv";
		arguments.filename = filenameWithoutExtension & "." & extension;
		downloadBinaryVariable( binary, arguments.filename, arguments.contentType );
	}

	public any function workbookFromCsv(
		string csv
		,string filepath
		,boolean firstRowIsHeader=false
		,boolean boldHeaderRow=true
		,boolean trim=true
		,boolean xmlFormat=false
		,string delimiter
	){
		var conversionArgs = {
			firstRowIsHeader: arguments.firstRowIsHeader
			,trim: arguments.trim
		};
		if( arguments.KeyExists( "csv" ) )
			conversionArgs.csv = arguments.csv;
		if( arguments.KeyExists( "filepath" ) )
			conversionArgs.filepath = arguments.filepath;
		if( arguments.KeyExists( "delimiter" ) )
			conversionArgs.delimiter = arguments.delimiter;
		var data = csvToQuery( argumentCollection=conversionArgs );
		return workbookFromQuery(
			data=data
			,addHeaderRow=arguments.firstRowIsHeader
			,boldHeaderRow=arguments.boldHeaderRow
			,xmlFormat=arguments.xmlFormat
		);
	}

	public any function workbookFromQuery(
		required query data
		,boolean addHeaderRow=true
		,boolean boldHeaderRow=true
		,boolean xmlFormat=false
		,boolean streamingXml=false
		,numeric streamingWindowSize=100
		,boolean ignoreQueryColumnDataTypes=false
		,struct datatypes
		,boolean autoSizeColumns=false
	){
		var workbook = new( xmlFormat=arguments.xmlFormat, streamingXml=arguments.streamingXml, streamingWindowSize=arguments.streamingWindowSize );
		var addRowsArgs = {
			workbook: workbook
			,data: arguments.data
			,ignoreQueryColumnDataTypes: arguments.ignoreQueryColumnDataTypes
			,autoSizeColumns: arguments.autoSizeColumns
		};
		if( arguments.KeyExists( "datatypes" ) )
			addRowsArgs.datatypes = arguments.datatypes;
		if( arguments.addHeaderRow ){
			var columns = _QueryColumnArray( arguments.data );
			addRow( workbook, columns );
			if( arguments.boldHeaderRow )
				formatRow( workbook, { bold: true }, 1 );
			addRowsArgs.row = 2;
			addRowsArgs.column = 1;
		}
		addRows( argumentCollection=addRowsArgs );
		return workbook;
	}

	public void function writeFileFromQuery(
		required query data
		,required string filepath
		,boolean overwrite=false
		,boolean addHeaderRow=true
		,boolean boldHeaderRow=true
		,boolean xmlFormat=false
		,boolean streamingXml=false
		,numeric streamingWindowSize=100
		,boolean ignoreQueryColumnDataTypes=false
		,struct datatypes
	){
		if( !arguments.xmlFormat && ( ListLast( arguments.filepath, "." ) == "xlsx" ) )
			arguments.xmlFormat = true;
		var workbookFromQueryArgs = {
			data: arguments.data
			,addHeaderRow: arguments.addHeaderRow
			,boldHeaderRow: arguments.boldHeaderRow
			,xmlFormat: arguments.xmlFormat
			,streamingXml: arguments.streamingXml
			,streamingWindowSize: arguments.streamingWindowSize
			,ignoreQueryColumnDataTypes: arguments.ignoreQueryColumnDataTypes
		};
		if( arguments.KeyExists( "datatypes" ) )
			workbookFromQueryArgs.datatypes = arguments.datatypes;
		var workbook = workbookFromQuery( argumentCollection=workbookFromQueryArgs );
		// force to .xlsx if appropriate
		if( xmlFormat && ( ListLast( arguments.filepath, "." ) == "xls" ) )
			arguments.filepath &= "x";
		write( workbook=workbook, filepath=arguments.filepath, overwrite=arguments.overwrite );
	}

	/* End convenience methods */

	public void function addAutofilter( required workbook, string cellRange="", numeric row=1 ){
		arguments.cellRange = arguments.cellRange.Trim();
		if( arguments.cellRange.IsEmpty() ){
			//default to all columns in the first (default) or specified row 
			var rowIndex = ( Max( 0, arguments.row -1 ) );
			var cellRangeAddress = getCellRangeAddressFromColumnAndRowIndices( rowIndex, rowIndex, 0, ( getColumnCount( arguments.workbook ) -1 ) );
			getActiveSheet( arguments.workbook ).setAutoFilter( cellRangeAddress );
			return;
		}
		getActiveSheet( arguments.workbook ).setAutoFilter( getCellRangeAddressFromReference( arguments.cellRange ) );
	}

	public void function addColumn(
		required workbook
		,required data // Delimited list of values OR array
		,numeric startRow
		,numeric startColumn
		,boolean insert=false
		,string delimiter=","
		,boolean autoSize=false
	){
		var sheet = getActiveSheet( arguments.workbook );
		var rowIndex = arguments.KeyExists( "startRow" )? ( arguments.startRow -1 ): 0;
		var cellIndex = 0;
		if( arguments.KeyExists( "startColumn" ) )
			cellIndex = ( arguments.startColumn -1 );
		else{
			var row = sheet.getRow( rowIndex );
			if( !IsNull( row ) && rowHasCells( row ) )
				cellIndex = getNextEmptyCellIndexFromRow( row );// append the new column to the existing columns
		}
		if( arguments.autoSize )
			var columnNumber = ( cellIndex +1 ); //stash the starting column number
		var columnData = IsArray( arguments.data )? arguments.data: ListToArray( arguments.data, arguments.delimiter );//Don't use ListToArray() member function: value may not support it
		for( var cellValue in columnData ){
			var row = sheet.getRow( rowIndex );
			if( rowIndex > sheet.getLastRowNum() || IsNull( row ) )
				row = createRow( arguments.workbook, rowIndex );
			// NB: row.getLastCellNum() returns the cell index PLUS ONE or -1 if not found
			var insertRequired = ( arguments.KeyExists( "startColumn" ) && arguments.insert && ( cellIndex < row.getLastCellNum() ) );
			if( insertRequired )
				shiftColumnsRightStartingAt( cellIndex, row, arguments.workbook );
			var cell = createCell( row, cellIndex );
			setCellValueAsType( arguments.workbook, cell, cellValue );
			rowIndex++;
		}
		if( arguments.autoSize )
			autoSizeColumn( arguments.workbook, columnNumber );
	}

	public void function addFreezePane(
		required workbook
		,required numeric freezeColumn
		,required numeric freezeRow
		,numeric leftmostColumn //left column visible in right pane
		,numeric topRow //top row visible in bottom pane
	){
		var sheet = getActiveSheet( arguments.workbook );
		if( arguments.KeyExists( "leftmostColumn" ) && !arguments.KeyExists( "topRow" ) )
			arguments.topRow = arguments.freezeRow;
		if( arguments.KeyExists( "topRow" ) && !arguments.KeyExists( "leftmostColumn" ) )
			arguments.leftmostColumn = arguments.freezeColumn;
		/* createFreezePane() operates on the logical row/column numbers as opposed to physical, so no need for n-1 stuff here */
		if( !arguments.KeyExists( "leftmostColumn" ) ){
			sheet.createFreezePane( JavaCast( "int", arguments.freezeColumn ), JavaCast( "int", arguments.freezeRow ) );
			return;
		}
		sheet.createFreezePane(
			JavaCast( "int", arguments.freezeColumn )
			,JavaCast( "int", arguments.freezeRow )
			,JavaCast( "int", arguments.leftmostColumn )
			,JavaCast( "int", arguments.topRow )
		);
	}

	public void function addImage(
		required workbook
		,string filepath
		,imageData
		,string imageType
		,required string anchor
	){
		var numberOfAnchorElements = ListLen( arguments.anchor );
		if( ( numberOfAnchorElements != 4 ) && ( numberOfAnchorElements != 8 ) )
			Throw( type=this.getExceptionType(), message="Invalid anchor argument", detail="The anchor argument must be a comma-delimited list of integers with either 4 or 8 elements" );
		var args = {
			workbook: arguments.workbook
			,anchor: arguments.anchor
		};
		if( arguments.KeyExists( "image" ) )
			args.image = arguments.image;//new alias instead of filepath/imageData
		if( arguments.KeyExists( "filepath" ) )
			args.image = arguments.filepath;
		if( arguments.KeyExists( "imageData" ) )
			args.image = arguments.imageData;
		if( arguments.KeyExists( "imageType" ) )
			args.imageType = arguments.imageType;
		if( !args.KeyExists( "image" ) )
			Throw( type=this.getExceptionType(), message="Missing image path or object", detail="Please supply either the 'filepath' or 'imageData' argument" );
		var imageIndex = addImageToWorkbook( argumentCollection=args );
		var clientAnchorClass = isXmlFormat( arguments.workbook )
				? "org.apache.poi.xssf.usermodel.XSSFClientAnchor"
				: "org.apache.poi.hssf.usermodel.HSSFClientAnchor";
		var theAnchor = loadClass( clientAnchorClass ).init();
		if( numberOfAnchorElements == 4 ){
			theAnchor.setRow1( JavaCast( "int", ListFirst( arguments.anchor ) -1 ) );
			theAnchor.setCol1( JavaCast( "int", ListGetAt( arguments.anchor, 2 ) -1 ) );
			theAnchor.setRow2( JavaCast( "int", ListGetAt( arguments.anchor, 3 ) -1 ) );
			theAnchor.setCol2( JavaCast( "int", ListLast( arguments.anchor ) -1 ) );
		}
		else if( numberOfAnchorElements == 8 ){
			theAnchor.setDx1( JavaCast( "int", ListFirst( arguments.anchor ) ) );
			theAnchor.setDy1( JavaCast( "int", ListGetAt( arguments.anchor, 2 ) ) );
			theAnchor.setDx2( JavaCast( "int", ListGetAt( arguments.anchor, 3 ) ) );
			theAnchor.setDy2( JavaCast( "int", ListGetAt( arguments.anchor, 4 ) ) );
			theAnchor.setRow1( JavaCast( "int", ListGetAt( arguments.anchor, 5 ) -1 ) );
			theAnchor.setCol1( JavaCast( "int", ListGetAt( arguments.anchor, 6 ) -1 ) );
			theAnchor.setRow2( JavaCast( "int", ListGetAt( arguments.anchor, 7 ) -1 ) );
			theAnchor.setCol2( JavaCast( "int", ListLast( arguments.anchor ) -1 ) );
		}
		/* (legacy note from spreadsheet extension) TODO: need to look into createDrawingPatriarch() vs. getDrawingPatriarch() since create will kill any existing images. getDrawingPatriarch() throws  a null pointer exception when an attempt is made to add a second image to the spreadsheet  */
		var drawingPatriarch = getActiveSheet( arguments.workbook ).createDrawingPatriarch();
		var picture = drawingPatriarch.createPicture( theAnchor, imageIndex );
	}

	public void function addInfo( required workbook, required struct info ){
		// Valid struct keys are author, category, lastauthor, comments, keywords, manager, company, subject, title
		if( isBinaryFormat( arguments.workbook ) )
			addInfoBinary( arguments.workbook, arguments.info );
		else
			addInfoXml( arguments.workbook, arguments.info );
	}

	public void function addPageBreaks( required workbook, string rowBreaks="", string columnBreaks="" ){
		arguments.rowBreaks = Trim( arguments.rowBreaks ); //Don't use member function in case value is in fact numeric
		arguments.columnBreaks = Trim( arguments.columnBreaks );
		if( arguments.rowBreaks.IsEmpty() && arguments.columnBreaks.IsEmpty() )
			Throw( type=this.getExceptionType(), message="Missing argument", detail="You must specify the rows and/or columns at which page breaks should be added." );
		arguments.rowBreaks = arguments.rowBreaks.ListToArray();
		arguments.columnBreaks = arguments.columnBreaks.ListToArray();
		var sheet = getActiveSheet( arguments.workbook );
		sheet.setAutoBreaks( false ); // Not sure if this is necessary: https://stackoverflow.com/a/14900320/204620
		for( var rowNumber in arguments.rowBreaks )
			sheet.setRowBreak( JavaCast( "int", ( rowNumber -1 ) ) );
		for( var columnNumber in arguments.columnBreaks )
			sheet.setcolumnBreak( JavaCast( "int", ( columnNumber -1 ) ) );
	}

	public void function addPrintGridlines( required workbook ){
		getActiveSheet( arguments.workbook ).setPrintGridlines( JavaCast( "boolean", true ) );
	}

	public void function addRow(
		required workbook
		,required data // Delimited list of data, OR array
		,numeric row
		,numeric column=1
		,boolean insert=true
		,string delimiter=","
		,boolean handleEmbeddedCommas=true // When true, values enclosed in single quotes are treated as a single element like in ACF. Only applies when the delimiter is a comma.
		,boolean autoSizeColumns=false
		,struct datatypes
	){
		if( arguments.KeyExists( "row" ) && ( arguments.row <= 0 ) )
			Throw( type=this.getExceptionType(), message="Invalid row value", detail="The value for row must be greater than or equal to 1." );
		if( arguments.KeyExists( "column" ) && ( arguments.column <= 0 ) )
			Throw( type=this.getExceptionType(), message="Invalid column value", detail="The value for column must be greater than or equal to 1." );
		if( !arguments.insert && !arguments.KeyExists( "row") )
			Throw( type=this.getExceptionType(), message="Missing row value", detail="To replace a row using 'insert', please specify the row to replace." );
		checkDataTypesArgument( arguments );
		var lastRow = getNextEmptyRowNumber( arguments.workbook );
		//If the requested row already exists...
		if( arguments.KeyExists( "row" ) && ( arguments.row <= lastRow ) ){
			if( arguments.insert )
				shiftRows( arguments.workbook, arguments.row, lastRow, 1 );//shift the existing rows down (by one row)
			else
				deleteRow( arguments.workbook, arguments.row );//otherwise, clear the entire row
		}
		var theRow = arguments.KeyExists( "row" )? createRow( arguments.workbook, arguments.row -1 ): createRow( arguments.workbook );
		var dataIsArray = IsArray( arguments.data );
		var rowValues = dataIsArray? arguments.data: parseListDataToArray( arguments.data, arguments.delimiter, arguments.handleEmbeddedCommas );
		var cellIndex = ( arguments.column -1 );
		for( var cellValue in rowValues ){
			var cell = createCell( theRow, cellIndex );
			if( arguments.KeyExists( "datatypes" ) )
   			setCellDataTypeWithOverride( arguments.workbook, cell, cellValue, cellIndex, arguments.datatypes );
   		else
				setCellValueAsType( arguments.workbook, cell, cellValue );
			if( arguments.autoSizeColumns )
				autoSizeColumn( arguments.workbook, arguments.column );
			cellIndex++;
		}
	}

	public void function addRows(
		required workbook
		,required data // query or array
		,numeric row
		,numeric column=1
		,boolean insert=true
		,boolean autoSizeColumns=false
		,boolean includeQueryColumnNames=false
		,boolean ignoreQueryColumnDataTypes=false
		,struct datatypes
	){
		var dataIsQuery = IsQuery( arguments.data );
		var dataIsArray = IsArray( arguments.data );
		if( !dataIsQuery && !dataIsArray )
			Throw( type=this.getExceptionType(), message="Invalid data argument", detail="The data passed in must be either a query or an array of row arrays." );
		checkDataTypesArgument( arguments );
		var totalRows = dataIsQuery? arguments.data.recordCount: arguments.data.Len();
		if( totalRows == 0 )
			return;
		// array data must be an array of arrays, not structs
		if( dataIsArray && !IsArray( arguments.data[ 1 ] ) )
			Throw( type=this.getExceptionType(), message="Invalid data argument", detail="Data passed as an array must be an array of arrays, one per row" );
		var lastRow = getNextEmptyRowNumber( arguments.workbook );
		var insertAtRowIndex = arguments.KeyExists( "row" )? arguments.row -1: getNextEmptyRowNumber( arguments.workbook );
		if( arguments.KeyExists( "row" ) && ( arguments.row <= lastRow ) && arguments.insert )
			shiftRows( arguments.workbook, arguments.row, lastRow, totalRows );
		var currentRowIndex = insertAtRowIndex;
		if( dataIsQuery ){
			var queryColumns = getQueryColumnTypeToCellTypeMappings( arguments.data );
			var cellIndex = ( arguments.column -1 );
			if( arguments.includeQueryColumnNames ){
				var columnNames = _QueryColumnArray( arguments.data );
				addRow( workbook=arguments.workbook, data=columnNames, row=currentRowIndex +1, column=arguments.column );
				currentRowIndex++;
			}
			if( arguments.KeyExists( "datatypes" ) ){
				param local.columnNames = _QueryColumnArray( arguments.data );
				convertDataTypeOverrideColumnNamesToNumbers( arguments.datatypes, columnNames );
			}
			for( var dataRow in arguments.data ){
				var newRow = createRow( arguments.workbook, currentRowIndex, false );
				cellIndex = ( arguments.column -1 );//reset for this row
	   		// populate all columns in the row
	   		for( var queryColumn in queryColumns ){
	   			var cell = createCell( newRow, cellIndex, false );
					var cellValue = dataRow[ queryColumn.name ];
					if( arguments.ignoreQueryColumnDataTypes ){
						if( arguments.KeyExists( "datatypes" ) )
		   				setCellDataTypeWithOverride( arguments.workbook, cell, cellValue, cellIndex, arguments.datatypes );
		   			else
							setCellValueAsType( arguments.workbook, cell, cellValue );
						cellIndex++;
						continue;
					}
					var cellValueType = getCellValueTypeFromQueryColumnType( queryColumn.cellDataType, cellValue );
					if( arguments.KeyExists( "datatypes" ) )
	   				setCellDataTypeWithOverride( arguments.workbook, cell, cellValue, cellIndex, arguments.datatypes, cellValueType );
	   			else
						setCellValueAsType( arguments.workbook, cell, cellValue, cellValueType );
					cellIndex++;
	   		}
	   		currentRowIndex++;
			}
			if( arguments.autoSizeColumns )
				_autoSizeColumns( workbook=arguments.workbook, startColumnNumber=arguments.column, endColumnNumber=queryColumns.Len() );
			return;
		}
		//data is an array
		for( var dataRow in arguments.data ){
			var newRow = createRow( arguments.workbook, currentRowIndex, false );
			var cellIndex = ( arguments.column -1 );
   		// populate all columns in the row
   		for( var cellValue in dataRow ){
   			var cell = createCell( newRow, cellIndex );
   			if( arguments.KeyExists( "datatypes" ) )
   				setCellDataTypeWithOverride( arguments.workbook, cell, cellValue, cellIndex, arguments.datatypes );
   			else
					setCellValueAsType( arguments.workbook, cell, cellValue );
				if( arguments.autoSizeColumns )
					autoSizeColumn( arguments.workbook, arguments.column );
				cellIndex++;
			}
			currentRowIndex++;
   	}
	}

	public void function addSplitPane(
		required workbook
		,required numeric xSplitPosition
		,required numeric ySplitPosition
		,required numeric leftmostColumn
		,required numeric topRow
		,string activePane="UPPER_LEFT" //Valid values are LOWER_LEFT, LOWER_RIGHT, UPPER_LEFT, and UPPER_RIGHT
	){
		var sheet = getActiveSheet( arguments.workbook );
		arguments.activePane = activeSheet[ "PANE_#arguments.activePane#" ];
		sheet.createSplitPane(
			JavaCast( "int", arguments.xSplitPosition )
			,JavaCast( "int", arguments.ySplitPosition )
			,JavaCast( "int", arguments.leftmostColumn )
			,JavaCast( "int", arguments.topRow )
			,JavaCast( "int", arguments.activePane )
		);
	}

	public void function autoSizeColumn( required workbook, required numeric column, boolean useMergedCells=false ){
		if( arguments.column <= 0 )
			Throw( type=this.getExceptionType(), message="Invalid column value", detail="The value for column must be greater than or equal to 1." );
		// Adjusts the width of the specified column to fit the contents. For performance reasons, this should normally be called only once per column.
		var columnIndex = ( arguments.column -1 );
		if( isStreamingXmlFormat( arguments.workbook ) )
			getActiveSheet( arguments.workbook ).trackColumnForAutoSizing( JavaCast( "int", columnIndex ) );
		getActiveSheet( arguments.workbook ).autoSizeColumn( columnIndex, arguments.useMergedCells );
	}

	public void function cleanUpStreamingXml( required workbook ){
		// SXSSF uses temporary files which MUST be cleaned up, see http://poi.apache.org/components/spreadsheet/how-to.html#sxssf
		if( isStreamingXmlFormat( arguments.workbook ) )
			arguments.workbook.dispose(); 
	}

	public void function clearCell( required workbook, required numeric row, required numeric column ){
		// Clears the specified cell of all styles and values
		var defaultStyle = arguments.workbook.getCellStyleAt( JavaCast( "short", 0 ) );
		var rowObject = getRowFromActiveSheet( arguments.workbook, arguments.row );
		if( IsNull( rowObject ) )
			return;
		var columnIndex = ( arguments.column -1 );
		var cell = rowObject.getCell( JavaCast( "int", columnIndex ) );
		if( IsNull( cell ) )
			return;
		cell.setCellStyle( defaultStyle );
		cell.setBlank();
	}

	public void function clearCellRange(
		required workbook
		,required numeric startRow
		,required numeric startColumn
		,required numeric endRow
		,required numeric endColumn
	){
		for( var rowNumber = arguments.startRow; rowNumber <= arguments.endRow; rowNumber++ ){
			for( var columnNumber = arguments.startColumn; columnNumber <= arguments.endColumn; columnNumber++ ){
				clearCell( arguments.workbook, rowNumber, columnNumber );
			}
		}
	}

	public any function createCellStyle( required workbook, required struct format ){
		return buildCellStyle( arguments.workbook, arguments.format );
	}

	public void function createSheet( required workbook, string sheetName, overwrite=false ){
		if( arguments.KeyExists( "sheetName" ) )
			validateSheetName( arguments.sheetName );
		else
			arguments.sheetName = generateUniqueSheetName( arguments.workbook );
		if( !sheetExists( workbook=arguments.workbook, sheetName=arguments.sheetName ) ){
			arguments.workbook.createSheet( JavaCast( "String", arguments.sheetName ) );
			return;
		}
		// sheet already exists with that name
		if( !arguments.overwrite )
			Throw( type=this.getExceptionType(), message="Sheet name already exists", detail="A sheet with the name '#arguments.sheetName#' already exists in this workbook" );
		// OK to replace the existing
		var sheetIndexToReplace = arguments.workbook.getSheetIndex( JavaCast( "string", arguments.sheetName ) );
		deleteSheetAtIndex( arguments.workbook, sheetIndexToReplace );
		var newSheet = arguments.workbook.createSheet( JavaCast( "String", arguments.sheetName ) );
		var moveToIndex = sheetIndexToReplace;
		moveSheet( arguments.workbook, arguments.sheetName, moveToIndex );
	}

	public void function deleteColumn( required workbook,required numeric column ){
		if( arguments.column <= 0 )
			Throw( type=this.getExceptionType(), message="Invalid column value", detail="The value for column must be greater than or equal to 1." );
			// POI doesn't have remove column functionality, so iterate over all the rows and remove the column indicated
		var rowIterator = getActiveSheet( arguments.workbook ).rowIterator();
		while( rowIterator.hasNext() ){
			var row = rowIterator.next();
			var cell = row.getCell( JavaCast( "int", ( arguments.column -1 ) ) );
			if( IsNull( cell ) )
				continue;
			row.removeCell( cell );
		}
	}

	public void function deleteColumns( required workbook, required string range ){
		// Validate and extract the ranges. Range is a comma-delimited list of ranges, and each value can be either a single number or a range of numbers with a hyphen.
		var allRanges = extractRanges( arguments.range );
		for( var thisRange in allRanges ){
			if( thisRange.startAt == thisRange.endAt ){ // Just one row
				deleteColumn( arguments.workbook, thisRange.startAt );
				continue;
			}
			for( var columnNumber = thisRange.startAt; columnNumber <= thisRange.endAt; columnNumber++ )
				deleteColumn( arguments.workbook, columnNumber );
		}
	}

	public void function deleteRow( required workbook, required numeric row ){
		// Deletes the data from a row. Does not physically delete the row
		if( arguments.row <= 0 )
			Throw( type=this.getExceptionType(), message="Invalid row value", detail="The value for row must be greater than or equal to 1." );
		var rowToDelete = ( arguments.row -1 );
		if( rowToDelete >= getFirstRowNumber( arguments.workbook ) && rowToDelete <= getLastRowNumber( arguments.workbook ) ) //If this is a valid row, remove it
			getActiveSheet( arguments.workbook ).removeRow( getRowFromActiveSheet( arguments.workbook, arguments.row ) );
	}

	public void function deleteRows( required workbook, required string range ){
		// Validate and extract the ranges. Range is a comma-delimited list of ranges, and each value can be either a single number or a range of numbers with a hyphen.
		var allRanges = extractRanges( arguments.range );
		for( var thisRange in allRanges ){
			if( thisRange.startAt == thisRange.endAt ){ // Just one row
				deleteRow( arguments.workbook, thisRange.startAt );
				continue;
			}
			for( var rowNumber = thisRange.startAt; rowNumber <= thisRange.endAt; rowNumber++ )
				deleteRow( arguments.workbook, rowNumber );
		}
	}

	public void function formatCell(
		required workbook
		,struct format={}
		,required numeric row
		,required numeric column
		,boolean overwriteCurrentStyle=true
		,any cellStyle
	){
		checkFormatArguments( argumentCollection=arguments );
		var cell = initializeCell( arguments.workbook, arguments.row, arguments.column );
		if( arguments.KeyExists( "cellStyle" ) ){
			cell.setCellStyle( arguments.cellStyle );
			return;
		}
		if( arguments.overwriteCurrentStyle ){
			cell.setCellStyle( buildCellStyle( arguments.workbook, arguments.format ) );
			return;
		}
		cell.setCellStyle( buildCellStyle( arguments.workbook, arguments.format, cell.getCellStyle() ) );
	}

	public void function formatCellRange(
		required workbook
		,struct format={}
		,required numeric startRow
		,required numeric endRow
		,required numeric startColumn
		,required numeric endColumn
		,boolean overwriteCurrentStyle=true
		,any cellStyle
	){
		checkFormatArguments( argumentCollection=arguments );
		var formatCellArgs = {
			workbook: arguments.workbook
			,format: arguments.format
			,overwriteCurrentStyle: arguments.overwriteCurrentStyle
		};
		addCellStyleToFormatMethodArgsIfStyleOverwriteAllowed( argumentCollection=arguments, formatMethodArgs=formatCellArgs );
		for( var rowNumber = arguments.startRow; rowNumber <= arguments.endRow; rowNumber++ ){
			for( var columnNumber = arguments.startColumn; columnNumber <= arguments.endColumn; columnNumber++ )
				formatCell( argumentCollection=formatCellArgs, row=rowNumber, column=columnNumber );
		}
	}

	public void function formatColumn(
		required workbook
		,struct format={}
		,required numeric column
		,boolean overwriteCurrentStyle=true
		,any cellStyle
	){
		checkFormatArguments( argumentCollection=arguments );
		if( arguments.column < 1 )
			Throw( type=this.getExceptionType(), message="Invalid column value", detail="The column value must be greater than 0" );
		var formatCellArgs = {
			workbook: arguments.workbook
			,format: arguments.format
			,column: arguments.column
			,overwriteCurrentStyle: arguments.overwriteCurrentStyle
		};
		addCellStyleToFormatMethodArgsIfStyleOverwriteAllowed( argumentCollection=arguments, formatMethodArgs=formatCellArgs );
		var rowIterator = getActiveSheet( arguments.workbook ).rowIterator();
		while( rowIterator.hasNext() ){
			var rowNumber = rowIterator.next().getRowNum() + 1;
			formatCell( argumentCollection=formatCellArgs, row=rowNumber );
		}
	}

	public void function formatColumns(
		required workbook
		,struct format={}
		,required string range
		,boolean overwriteCurrentStyle=true
		,any cellStyle
	){
		checkFormatArguments( argumentCollection=arguments );
		// Validate and extract the ranges. Range is a comma-delimited list of ranges, and each value can be either a single number or a range of numbers with a hyphen.
		var allRanges = extractRanges( arguments.range );
		var formatColumnArgs = {
			workbook: arguments.workbook
			,format: arguments.format
			,overwriteCurrentStyle: arguments.overwriteCurrentStyle
		};
		addCellStyleToFormatMethodArgsIfStyleOverwriteAllowed( argumentCollection=arguments, formatMethodArgs=formatColumnArgs );
		for( var thisRange in allRanges ){
			if( thisRange.startAt == thisRange.endAt ){ // Just one column
				formatColumn( argumentCollection=formatColumnArgs, column=thisRange.startAt );
				continue;
			}
			for( var columnNumber = thisRange.startAt; columnNumber <= thisRange.endAt; columnNumber++ )
				formatColumn( argumentCollection=formatColumnArgs, column=columnNumber );
		}
	}

	public void function formatRow(
		required workbook
		,struct format={}
		,required numeric row
		,boolean overwriteCurrentStyle=true
		,any cellStyle
	){
		checkFormatArguments( argumentCollection=arguments );
		var theRow = getRowFromActiveSheet( arguments.workbook, arguments.row );
		if( IsNull( theRow ) )
			return;
		var formatCellArgs = {
			workbook: arguments.workbook
			,format: arguments.format
			,row: arguments.row
			,overwriteCurrentStyle: arguments.overwriteCurrentStyle
		};
		addCellStyleToFormatMethodArgsIfStyleOverwriteAllowed( argumentCollection=arguments, formatMethodArgs=formatCellArgs );
		var cellIterator = theRow.cellIterator();
		while( cellIterator.hasNext() ){
			var columnNumber = ( cellIterator.next().getColumnIndex() +1 );
			formatCell( argumentCollection=formatCellArgs, column=columnNumber );
		}
	}

	public void function formatRows(
		required workbook
		,struct format={}
		,required string range
		,boolean overwriteCurrentStyle=true
		,any cellStyle
	){
		checkFormatArguments( argumentCollection=arguments );
		// Validate and extract the ranges. Range is a comma-delimited list of ranges, and each value can be either a single number or a range of numbers with a hyphen.
		var allRanges = extractRanges( arguments.range );
		var formatRowArgs = {
			workbook: arguments.workbook
			,format: arguments.format
			,overwriteCurrentStyle: arguments.overwriteCurrentStyle
		};
		addCellStyleToFormatMethodArgsIfStyleOverwriteAllowed( argumentCollection=arguments, formatMethodArgs=formatRowArgs );
		for( var thisRange in allRanges ){
			if( thisRange.startAt == thisRange.endAt ){ // Just one row
				formatRow( arguments.workbook, arguments.format, thisRange.startAt, arguments.overwriteCurrentStyle, style );
				continue;
			}
			for( var rowNumber = thisRange.startAt; rowNumber <= thisRange.endAt; rowNumber++ )
				formatRow( argumentCollection=formatRowArgs, row=rowNumber );
		}
	}

	public any function getCellComment( required workbook, numeric row, numeric column ){
		if( arguments.KeyExists( "row" ) && !arguments.KeyExists( "column" ) )
			Throw( type=this.getExceptionType(), message="Invalid argument combination", detail="If you specify the row you must also specify the column" );
		if( arguments.KeyExists( "column" ) && !arguments.KeyExists( "row" ) )
			Throw( type=this.getExceptionType(), message="Invalid argument combination", detail="If you specify the column you must also specify the row" );
		if( arguments.KeyExists( "row" ) ){
			var cell = getCellAt( arguments.workbook, arguments.row, arguments.column );
			var commentObject = cell.getCellComment();
			if( !IsNull( commentObject ) ){
				return {
					author: commentObject.getAuthor()
					,comment: commentObject.getString().getString()
					,column: arguments.column
					,row: arguments.row
				};
			}
			return {};
		}
		// row and column weren't provided so return all the comments as an array of structs
		return getCellComments( arguments.workbook );
	}

	public array function getCellComments( required workbook ){
		var comments = [];
		var commentsIterator = getActiveSheet( arguments.workbook ).getCellComments().values().iterator();
		while( commentsIterator.hasNext() ){
			var commentObject = commentsIterator.next();
			var comment = {
				author: commentObject.getAuthor()
				,comment: commentObject.getString().getString()
				,column: ( commentObject.getColumn() +1 )
				,row: ( commentObject.getRow() +1 )
			};
			comments.Append( comment );
		}
		return comments;
	}

	public struct function getCellFormat( required workbook, required numeric row, required numeric column ){
		if( !cellExists( arguments.workbook, arguments.row, arguments.column ) )
			Throw( type=this.getExceptionType(), message="Invalid cell", detail="There doesn't appear to be a cell at row #row#, column #column#" );
		var cellStyle = getCellAt( arguments.workbook, arguments.row, arguments.column ).getCellStyle();
		var cellFont = arguments.workbook.getFontAt( cellStyle.getFontIndexAsInt() );
		if( isXmlFormat( arguments.workbook ) )
			var rgb = convertSignedRGBToPositiveTriplet( cellFont.getXSSFColor().getRGB() );
		else
			var rgb = IsNull( cellFont.getHSSFColor( arguments.workbook ) )? []: cellFont.getHSSFColor( arguments.workbook ).getTriplet();
		return {
			alignment: cellStyle.getAlignment().toString()
			,bold: cellFont.getBold()
			,bottomborder: cellStyle.getBorderBottom().toString()
			,bottombordercolor: getRgbTripletForStyleColorFormat( arguments.workbook, cellStyle, "bottombordercolor" )
			,color: ArrayToList( rgb )
			,dataformat: cellStyle.getDataFormatString()
			,fgcolor: getRgbTripletForStyleColorFormat( arguments.workbook, cellStyle, "fgcolor" )
			,fillpattern: cellStyle.getFillPattern().toString()
			,font: cellFont.getFontName()
			,fontsize: cellFont.getFontHeightInPoints()
			,indent: cellStyle.getIndention()
			,italic: cellFont.getItalic()
			,leftborder: cellStyle.getBorderLeft().toString()
			,leftbordercolor: getRgbTripletForStyleColorFormat( arguments.workbook, cellStyle, "leftbordercolor" )
			,quoteprefixed: cellStyle.getQuotePrefixed()
			,rightborder: cellStyle.getBorderRight().toString()
			,rightbordercolor: getRgbTripletForStyleColorFormat( arguments.workbook, cellStyle, "rightbordercolor" )
			,rotation: cellStyle.getRotation()
			,strikeout: cellFont.getStrikeout()
			,textwrap: cellStyle.getWrapText()
			,topborder: cellStyle.getBorderTop().toString()
			,topbordercolor: getRgbTripletForStyleColorFormat( arguments.workbook, cellStyle, "topbordercolor" )
			,underline: lookupUnderlineFormatCode( cellFont )
			,verticalalignment: cellStyle.getVerticalAlignment().toString()
		};
	}

	public any function getCellFormula( required workbook, numeric row, numeric column ){
		if( !arguments.KeyExists( "row" ) || !arguments.KeyExists( "column" ) )
			return getAllSheetFormulas( arguments.workbook );
		if( !cellExists( arguments.workbook, arguments.row, arguments.column ) )
			return "";
		var cell = getCellAt( arguments.workbook, arguments.row, arguments.column );
		if( cellIsOfType( cell, "FORMULA" ) )
			return cell.getCellFormula();
		return "";
	}

	public string function getCellHyperLink( required workbook, required numeric row, required numeric column ){
		var cell = initializeCell( arguments.workbook, arguments.row, arguments.column );
		return cell.getHyperLink()?.getAddress()?:"";
	}

	public string function getCellType( required workbook, required numeric row, required numeric column ){
		if( !cellExists( arguments.workbook, arguments.row, arguments.column ) )
			return "";
		var rowObject = getRowFromActiveSheet( arguments.workbook, arguments.row );
		var columnIndex = ( arguments.column -1 );
		var cell = rowObject.getCell( JavaCast( "int", columnIndex ) );
		return cell.getCellType().toString();
	}

	public any function getCellValue( required workbook, required numeric row, required numeric column ){
		if( !cellExists( arguments.workbook, arguments.row, arguments.column ) )
			return "";
		var rowObject = getRowFromActiveSheet( arguments.workbook, arguments.row );
		var columnIndex = ( arguments.column -1 );
		var cell = rowObject.getCell( JavaCast( "int", columnIndex ) );
		if( cellIsOfType( cell, "FORMULA" ) )
			return getCellFormulaValue( arguments.workbook, cell );
		return getDataFormatter().formatCellValue( cell );
	}

	public numeric function getColumnCount( required workbook, sheetNameOrNumber ){
		if( arguments.KeyExists( "sheetNameOrNumber" ) )
			setActiveSheetNameOrNumber( argumentCollection=arguments );
		var sheet = getActiveSheet( arguments.workbook );
		var rowIterator = sheet.rowIterator();
		var result = 0;
		while( rowIterator.hasNext() ){
			var row = rowIterator.next();
			result = Max( result, row.getLastCellNum() );
		}
		return result;
	}

	public numeric function getColumnWidth( required workbook, required numeric column ){
		var columnIndex = ( arguments.column -1 );
		return ( getActiveSheet( arguments.workbook ).getColumnWidth( JavaCast( "int", columnIndex ) ) / 256 );// whole character width (of zero character)
	}

	public numeric function getColumnWidthInPixels( required workbook, required numeric column ){
		var columnIndex = ( arguments.column -1 );
		return getActiveSheet( arguments.workbook ).getColumnWidthInPixels( JavaCast( "int", columnIndex ) );
	}

	public array function getPresetColorNames(){
		var presetEnum = loadClass( "org.apache.poi.hssf.util.HSSFColor$HSSFColorPredefined" );
		var result = [];
		for( var value in presetEnum.values() )
			result.Append( value.name() );
		result.Sort( "text" );//ACF2016 (not 2018) returns "YES" from a sort instead of the sorted array, so perform sort separately.
		return result;
	}

	public numeric function getRowCount( required workbook, sheetNameOrNumber ){
		if( arguments.KeyExists( "sheetNameOrNumber" ) )
			setActiveSheetNameOrNumber( argumentCollection=arguments );
		var sheet = getActiveSheet( arguments.workbook );
		var lastRowIndex = getLastRowNumber( arguments.workbook, sheet );
		if( lastRowIndex == -1 ) // empty
			return 0;
		return lastRowIndex +1;
	}

	public void function hideColumn( required workbook, required numeric column ){
		toggleColumnHidden( arguments.workbook, arguments.column, true );
	}

	public void function hideRow( required workbook, required numeric row ){
		toggleRowHidden( arguments.workbook, arguments.row, true );
	}

	public struct function info( required workbookOrPath ){
		/*
		properties returned in the struct are:
			* AUTHOR
			* CATEGORY
			* COMMENTS
			* CREATIONDATE
			* LASTEDITED
			* LASTAUTHOR
			* LASTSAVED
			* KEYWORDS
			* MANAGER
			* COMPANY
			* SUBJECT
			* TITLE
			* SHEETS
			* SHEETNAMES
			* SPREADSHEETTYPE
		*/
		if( this.isSpreadsheetObject( arguments[ 1 ] ) ) //use this scope to avoid clash with ACF built-in function
			var workbook = arguments[ 1 ];
		else
			var workbook = workbookFromFile( arguments[ 1 ] );
		//format specific metadata
		var info = isBinaryFormat( workbook )? binaryInfo( workbook ): xmlInfo( workbook );
		//common properties
		info.sheets = workbook.getNumberOfSheets();
		var sheetnames = [];
		if( IsNumeric( info.sheets ) ){
			for( var i = 1; i <= info.sheets; i++ )
				sheetnames.Append( workbook.getSheetName( JavaCast( "int", ( i -1 ) ) ) );
			info.sheetnames = sheetnames.ToList();
		}
		info.spreadSheetType = isXmlFormat( workbook )? "Excel (2007)": "Excel";
		return info;
	}

	public boolean function isBinaryFormat( required workbook ){
		return arguments.workbook.getClass().getCanonicalName() == this.getHSSFWorkbookClassName();
	}

	public boolean function isColumnHidden( required workbook, required numeric column ){
		return getActiveSheet( arguments.workbook ).isColumnHidden( arguments.column - 1 );
	}

	public boolean function isRowHidden( required workbook, required numeric row ){
		return getRowFromActiveSheet( arguments.workbook, arguments.row ).getZeroHeight();
	}

	public boolean function isSpreadsheetFile( required string path ){
		throwErrorIFfileNotExists( arguments.path );
		try{
			var workbook = workbookFromFile( arguments.path );
		}
		catch( cfsimplicity.lucee.spreadsheet.invalidFile exception ){
			return false;
		}
		return true;
	}

	public boolean function isSpreadsheetObject( required object ){
		return isBinaryFormat( arguments.object ) || isXmlFormat( arguments.object );
	}

	public boolean function isXmlFormat( required workbook ){
		//CF2016 doesn't support [].Find( needle );
		return ArrayFind( [ this.getXSSFWorkbookClassName(), this.getSXSSFWorkbookClassName() ], arguments.workbook.getClass().getCanonicalName() );
	}

	public boolean function isStreamingXmlFormat( required workbook ){
		return arguments.workbook.getClass().getCanonicalName() == this.getSXSSFWorkbookClassName();
	}

	public void function mergeCells(
		required workbook
		,required numeric startRow
		,required numeric endRow
		,required numeric startColumn
		,required numeric endColumn
		,boolean emptyInvisibleCells=false
	){
		if( arguments.startRow < 1 || arguments.startRow > arguments.endRow )
			Throw( type=this.getExceptionType(), message="Invalid startRow or endRow", detail="Row values must be greater than 0 and the startRow cannot be greater than the endRow." );
		if( arguments.startColumn < 1 || arguments.startColumn > arguments.endColumn )
			Throw( type=this.getExceptionType(), message="Invalid startColumn or endColumn", detail="Column values must be greater than 0 and the startColumn cannot be greater than the endColumn." );
		var cellRangeAddress = getCellRangeAddressFromColumnAndRowIndices(
			( arguments.startRow - 1 )
			,( arguments.endRow - 1 )
			,( arguments.startColumn - 1 )
			,( arguments.endColumn - 1 )
		);
		getActiveSheet( arguments.workbook ).addMergedRegion( cellRangeAddress );
		if( !arguments.emptyInvisibleCells )
			return;
		// stash the value to retain
		var visibleValue = getCellValue( arguments.workbook, arguments.startRow, arguments.startColumn );
		//empty all cells in the merged region
		setCellRangeValue( arguments.workbook, "", arguments.startRow, arguments.endRow, arguments.startColumn, arguments.endColumn );
		//restore the stashed value
		setCellValue( arguments.workbook, visibleValue, arguments.startRow, arguments.startColumn );
	}

	public any function new(
		string sheetName="Sheet1"
		,boolean xmlFormat=false
		,boolean streamingXml=false
		,numeric streamingWindowSize
	){
		if( arguments.streamingXml && !arguments.xmlFormat )
			arguments.xmlFormat = true;
		var workbook = createWorkBook( argumentCollection=arguments );
		createSheet( workbook, arguments.sheetName, arguments.xmlFormat );
		setActiveSheet( workbook, arguments.sheetName );
		return workbook;
	}

	public any function newXls( string sheetName="Sheet1" ){
		return new( sheetName=arguments.sheetName, xmlFormat=false );
	}

	public any function newXlsx( string sheetName="Sheet1" ){
		return new( sheetName=arguments.sheetName, xmlFormat=true );
	}

	public any function newStreamingXlsx( string sheetName="Sheet1", numeric streamingWindowSize=100 ){
		return new(
			sheetName=arguments.sheetName
			,xmlFormat=true
			,streamingXml=true
			,streamingWindowSize=arguments.streamingWindowSize
		);
	}

	public string function queryToCsv( required query query, boolean includeHeaderRow=false, string delimiter="," ){		
		var data = [];
		var columns = _QueryColumnArray( arguments.query );
		if( arguments.includeHeaderRow )
			data.Append( columns );
		for( var row IN arguments.query ){
			var rowValues = [];
			for( var column IN columns ){
				var cellValue = row[ column ];
				if( isDateObject( cellValue ) || _IsDate( cellValue ) )
					cellValue = DateTimeFormat( cellValue, this.getDateFormats().DATETIME );
				if( IsValid( "integer", cellValue ) )
					cellValue = JavaCast( "string", cellValue );// prevent CSV writer converting 1 to 1.0
				rowValues.Append( cellValue );
			}
			data.Append( rowValues );
		}
		var builder = newJavaStringBuilder();
		if( delimiterIsTab( arguments.delimiter ) )
			var csvFormat = loadClass( "org.apache.commons.csv.CSVFormat" )[ JavaCast( "string", "TDF" ) ];
		else
			var csvFormat = loadClass( "org.apache.commons.csv.CSVFormat" )[ JavaCast( "string", "EXCEL" ) ]
				.withDelimiter( JavaCast( "char", arguments.delimiter ) );
		loadClass( "org.apache.commons.csv.CSVPrinter" )
			.init( builder, csvFormat )
			.printRecords( data );
		return builder.toString().Trim();
	}

	public any function read(
		required string src
		,string format
		,string columns
		,any columnNames //list or array
		,numeric headerRow
		,string rows
		,string sheetName
		,numeric sheetNumber // 1-based
		,boolean includeHeaderRow=false
		,boolean includeBlankRows=false
		,boolean fillMergedCellsWithVisibleValue=false
		,boolean includeHiddenColumns=true
		,boolean includeRichTextFormatting=false
		,string password
		,string csvDelimiter=","
		,any queryColumnTypes //'auto', list of types, or struct of column names/types mapping. Null means no types are specified.
		,boolean makeColumnNamesSafe=false
	){
		if( arguments.KeyExists( "query" ) )
			Throw( type=this.getExceptionType(), message="Invalid argument 'query'.", detail="Just use format='query' to return a query object" );
		if( arguments.KeyExists( "format" ) && !ListFindNoCase( "query,html,csv", arguments.format ) )
			Throw( type=this.getExceptionType(), message="Invalid format", detail="Supported formats are: 'query', 'html' and 'csv'" );
		if( arguments.KeyExists( "sheetName" ) && arguments.KeyExists( "sheetNumber" ) )
			Throw( type=this.getExceptionType(), message="Cannot provide both sheetNumber and sheetName arguments", detail="Only one of either 'sheetNumber' or 'sheetName' arguments may be provided." );
		throwErrorIFfileNotExists( arguments.src );
		var passwordProtected = ( arguments.KeyExists( "password") && !arguments.password.Trim().IsEmpty() );
		var workbook = passwordProtected? workbookFromFile( arguments.src, arguments.password ): workbookFromFile( arguments.src );
		if( arguments.KeyExists( "sheetName" ) )
			setActiveSheet( workbook=workbook, sheetName=arguments.sheetName );
		if( !arguments.KeyExists( "format" ) )
			return workbook;
		var args = { workbook: workbook };
		if( arguments.KeyExists( "sheetName" ) )
			args.sheetName = arguments.sheetName;
		if( arguments.KeyExists( "sheetNumber" ) )
			args.sheetNumber = arguments.sheetNumber;
		if( arguments.KeyExists( "headerRow" ) ){
			args.headerRow = arguments.headerRow;
			args.includeHeaderRow = arguments.includeHeaderRow;
		}
		if( arguments.KeyExists( "rows" ) )
			args.rows = arguments.rows;
		if( arguments.KeyExists( "columns" ) )
			args.columns = arguments.columns;
		if( arguments.KeyExists( "columnNames" ) )
			args.columnNames = arguments.columnNames; // columnNames is what cfspreadsheet action="read" uses
		else if( arguments.KeyExists( "queryColumnNames" ) )
			args.columnNames = arguments.queryColumnNames;// accept better alias `queryColumnNames` to match csvToQuery
		if( ( arguments.format == "query" ) && arguments.KeyExists( "queryColumnTypes" ) ){
			throwErrorIFinvalidQueryColumnTypesArgument( argumentCollection=arguments );
			args.queryColumnTypes = arguments.queryColumnTypes;
		}
		args.includeBlankRows = arguments.includeBlankRows;
		args.fillMergedCellsWithVisibleValue = arguments.fillMergedCellsWithVisibleValue;
		args.includeHiddenColumns = arguments.includeHiddenColumns;
		args.includeRichTextFormatting = arguments.includeRichTextFormatting;
		args.makeColumnNamesSafe = arguments.makeColumnNamesSafe;
		var generatedQuery = sheetToQuery( argumentCollection=args );
		if( arguments.format == "query" )
			return generatedQuery;
		var args = { query: generatedQuery };
		if( arguments.KeyExists( "headerRow" ) ){
			args.headerRow = arguments.headerRow;
			args.includeHeaderRow = arguments.includeHeaderRow;
		}
		switch( arguments.format ){
			case "csv":
				args.delimiter = arguments.csvDelimiter;
				return queryToCsv( argumentCollection=args );
			case "html": return queryToHtml( argumentCollection=args );
		}
	}

	public binary function readBinary( required workbook ){
		var baos = loadClass( "org.apache.commons.io.output.ByteArrayOutputStream" ).init();
		arguments.workbook.write( baos );
		baos.flush();
		return baos.toByteArray();
	}

	public void function removePrintGridlines( required workbook ){
		getActiveSheet( arguments.workbook ).setPrintGridlines( JavaCast( "boolean", false ) );
	}

	public void function removeSheet( required workbook, required string sheetName ){
		validateSheetName( arguments.sheetName );
		validateSheetExistsWithName( arguments.workbook, arguments.sheetName );
		arguments.sheetNumber = ( arguments.workbook.getSheetIndex( arguments.sheetName ) +1 );
		var sheetIndex = ( sheetNumber -1 );
		deleteSheetAtIndex( arguments.workbook, sheetIndex );
	}

	public void function removeSheetNumber( required workbook, required numeric sheetNumber ){
		validateSheetNumber( arguments.workbook, arguments.sheetNumber );
		var sheetIndex = ( arguments.sheetNumber -1 );
		deleteSheetAtIndex( arguments.workbook, sheetIndex );
	}

	public void function renameSheet( required workbook, required string sheetName, required numeric sheetNumber ){
		validateSheetName( arguments.sheetName );
		validateSheetNumber( arguments.workbook, arguments.sheetNumber );
		var sheetIndex = ( arguments.sheetNumber -1 );
		var foundAt = arguments.workbook.getSheetIndex( JavaCast( "string", arguments.sheetName ) );
		if( ( foundAt > 0 ) && ( foundAt != sheetIndex ) )
			Throw( type=this.getExceptionType(), message="Invalid Sheet Name [#arguments.sheetName#]", detail="The workbook already contains a sheet named [#sheetName#]. Sheet names must be unique" );
		arguments.workbook.setSheetName( JavaCast( "int", sheetIndex ), JavaCast( "string", arguments.sheetName ) );
	}

	public void function setActiveCell( required workbook, required numeric row, required numeric column ){
		var sheet = getActiveSheet( arguments.workbook );
		var cell = initializeCell( arguments.workbook, arguments.row, arguments.column );
		var cellAddress = loadClass( "org.apache.poi.ss.util.CellAddress" ).init( cell );
		sheet.setActiveCell( cellAddress );
	}

	public void function setActiveSheet( required workbook, string sheetName, numeric sheetNumber ){
		validateSheetNameOrNumberWasProvided( argumentCollection=arguments );
		if( arguments.KeyExists( "sheetName" ) ){
			validateSheetExistsWithName( arguments.workbook, arguments.sheetName );
			arguments.sheetNumber = ( arguments.workbook.getSheetIndex( JavaCast( "string", arguments.sheetName ) ) + 1 );
		}
		validateSheetNumber( arguments.workbook, arguments.sheetNumber );
		arguments.workbook.setActiveSheet( JavaCast( "int", ( arguments.sheetNumber - 1 ) ) );
	}

	public void function setActiveSheetNumber( required workbook, numeric sheetNumber ){
		setActiveSheet( workbook=arguments.workbook, sheetNumber=arguments.sheetNumber );
	}

	public void function setCellComment(
		required workbook
		,required struct comment
		,required numeric row
		,required numeric column
	){
		/*
		The comment struct may contain the following keys:
			* anchor
			* author
			* bold
			* color
			* comment
			* fillcolor
			* font
			* horizontalalignment
			* italic
			* linestyle
			* linestylecolor
			* size
			* strikeout
			* underline
			* verticalalignment
			* visible
		 */
		var factory = arguments.workbook.getCreationHelper();
		var commentString = factory.createRichTextString( JavaCast( "string", arguments.comment.comment ) );
		var anchor = factory.createClientAnchor();
		var anchorValues = {};
		if( arguments.comment.KeyExists( "anchor" ) ){
			//specifies the position and size of the comment, e.g. "4,8,6,11"
			var anchorValueArray = arguments.comment.anchor.ListToArray();
			anchorValues.col1 = anchorValueArray[ 1 ];
			anchorValues.row1 = anchorValueArray[ 2 ];
			anchorValues.col2 = anchorValueArray[ 3 ];
			anchorValues.row2 = anchorValueArray[ 4 ];
		}
		else{
			//no position specified, so use the row/column values to set a default
			anchorValues.col1 = arguments.column;
			anchorValues.row1 = arguments.row;
			anchorValues.col2 = ( arguments.column +2 );
			anchorValues.row2 = ( arguments.row +2 );
		}
		anchor.setRow1( JavaCast( "int", anchorValues.row1 ) );
		anchor.setCol1( JavaCast( "int", anchorValues.col1 ) );
		anchor.setRow2( JavaCast( "int", anchorValues.row2 ) );
		anchor.setCol2( JavaCast( "int", anchorValues.col2 ) );
		var drawingPatriarch = getActiveSheet( arguments.workbook ).createDrawingPatriarch();
		var commentObject = drawingPatriarch.createCellComment( anchor );
		if( arguments.comment.KeyExists( "author" ) )
			commentObject.setAuthor( JavaCast( "string", arguments.comment.author ) );
		if( arguments.comment.KeyExists( "visible" ) )
			commentObject.setVisible( JavaCast( "boolean", arguments.comment.visible ) );//doesn't always seem to work
		// If we're going to do anything font related, need to create a font. Didn't really want to create it above since it might not be needed.
		var commentHasFontStyles = (
			arguments.comment.KeyExists( "bold" )
			|| arguments.comment.KeyExists( "color" )
			|| arguments.comment.KeyExists( "font" )
			|| arguments.comment.KeyExists( "italic" )
			|| arguments.comment.KeyExists( "size" )
			|| arguments.comment.KeyExists( "strikeout" )
			|| arguments.comment.KeyExists( "underline" )
		);
		if( commentHasFontStyles ){
			var font = workbook.createFont();
			if( arguments.comment.KeyExists( "bold" ) )
				font.setBold( JavaCast( "boolean", arguments.comment.bold ) );
			if( arguments.comment.KeyExists( "color" ) )
				font.setColor( getColor( workbook, arguments.comment.color ) );
			if( arguments.comment.KeyExists( "font" ) )
				font.setFontName( JavaCast( "string", arguments.comment.font ) );
			if( arguments.comment.KeyExists( "italic" ) )
				font.setItalic( JavaCast( "string", arguments.comment.italic ) );
			if( arguments.comment.KeyExists( "size" ) )
				font.setFontHeightInPoints( JavaCast( "int", arguments.comment.size ) );
			if( arguments.comment.KeyExists( "strikeout" ) )
				font.setStrikeout( JavaCast( "boolean", arguments.comment.strikeout ) );
			if( arguments.comment.KeyExists( "underline" ) )
				font.setUnderline( JavaCast( "byte", arguments.comment.underline ) );
			commentString.applyFont( font );
		}
		var workbookIsHSSF = isBinaryFormat( arguments.workbook );
		//the following 5 properties are not currently supported on XSSFComment: https://github.com/cfsimplicity/lucee-spreadsheet/issues/192
		if( workbookIsHSSF && arguments.comment.KeyExists( "fillColor" ) ){
			var javaColorRGB = getJavaColorRGBFor( arguments.comment.fillColor );
			commentObject.setFillColor(
				JavaCast( "int", javaColorRGB.red )
				,JavaCast( "int", javaColorRGB.green )
				,JavaCast( "int", javaColorRGB.blue )
			);
		}
		if( workbookIsHSSF && arguments.comment.KeyExists( "lineStyle" ) )
		 	commentObject.setLineStyle( JavaCast( "int", commentObject[ "LINESTYLE_" & arguments.comment.lineStyle.UCase() ] ) );
		if( workbookIsHSSF && arguments.comment.KeyExists( "lineStyleColor" ) ){
			var javaColorRGB = getJavaColorRGBFor( arguments.comment.lineStyleColor );
			commentObject.setLineStyleColor(
				JavaCast( "int", javaColorRGB.red )
				,JavaCast( "int", javaColorRGB.green )
				,JavaCast( "int", javaColorRGB.blue )
			);
		}
		/* Horizontal alignment can be left, center, right, justify, or distributed. Note that the constants on the Java class are slightly different in some cases: 'center'=CENTERED 'justify'=JUSTIFIED */
		if( workbookIsHSSF && arguments.comment.KeyExists( "horizontalAlignment" ) ){
			if( arguments.comment.horizontalAlignment.UCase() == "CENTER" )
				arguments.comment.horizontalAlignment = "CENTERED";
			if( arguments.comment.horizontalAlignment.UCase() == "JUSTIFY" )
				arguments.comment.horizontalAlignment = "JUSTIFIED";
			commentObject.setHorizontalAlignment( JavaCast( "int", commentObject[ "HORIZONTAL_ALIGNMENT_" & arguments.comment.horizontalalignment.UCase() ] ) );
		}
		/* Vertical alignment can be top, center, bottom, justify, and distributed. Note that center and justify are DIFFERENT than the constants for horizontal alignment, which are CENTERED and JUSTIFIED. */
		if( workbookIsHSSF && arguments.comment.KeyExists( "verticalAlignment" ) )
			commentObject.setVerticalAlignment( JavaCast( "int", commentObject[ "VERTICAL_ALIGNMENT_" & arguments.comment.verticalAlignment.UCase() ] ) );
		//END HSSF only styles
		commentObject.setString( commentString );
		var cell = initializeCell( arguments.workbook, arguments.row, arguments.column );
		cell.setCellComment( commentObject );
	}

	public void function setCellFormula(
		required workbook
		,required string formula
		,required numeric row
		,required numeric column
	){
		var cell = initializeCell( arguments.workbook, arguments.row, arguments.column );
		cell.setCellFormula( JavaCast( "string", arguments.formula ) );
	}
	
	public void function setCellHyperlink(
		required workbook
		,required string link
		,required numeric row
		,required numeric column
		,any cellValue
		,string type="URL"
		,struct format={ color: "BLUE", underline: true }
		,string tooltip //xlsx only, maybe MS Excel full version only
	){
		arguments.type = arguments.type.UCase();
		var validTypes = [ "URL", "EMAIL", "FILE", "DOCUMENT" ];
		if( !validTypes.Find( arguments.type ) )
			Throw( type=this.getExceptionType(), message="Invalid type parameter: '#arguments.type#'", detail="The type must be one of the following: #validTypes.ToList( ', ' )#." );
		if( arguments.KeyExists( "tooltip" ) && !isXmlFormat( arguments.workbook ) )
			Throw( type=this.getExceptionType(), message="Invalid spreadsheet type", detail="Hyperlink tooltips can only be added to XLSX spreadsheets." );
		var cell = initializeCell( arguments.workbook, arguments.row, arguments.column );
		var hyperlinkType = loadClass( "org.apache.poi.common.usermodel.HyperlinkType" );
		var hyperLink = arguments.workbook.getCreationHelper().createHyperlink( hyperlinkType[ arguments.type ] );
		hyperLink.setAddress( JavaCast( "string", arguments.link ) );
		if( arguments.KeyExists( "tooltip" ) )
			hyperLink.setTooltip( JavaCast( "string", arguments.tooltip ) );
		cell.setHyperlink( hyperLink );
		if( arguments.KeyExists( "cellValue" ) )
			setCellValueAsType( arguments.workbook, cell, arguments.cellValue );
		if( !arguments.format.IsEmpty() )
			formatCell( arguments.workbook, arguments.format, arguments.row, arguments.column );
	}

	public void function setCellRangeValue(
		required workbook
		,required value
		,required numeric startRow
		,required numeric endRow
		,required numeric startColumn
		,required numeric endColumn
	){
		for( var rowNumber = arguments.endRow; rowNumber >= arguments.startRow; rowNumber-- ){
			for( var columnNumber = arguments.endColumn; columnNumber >= arguments.startColumn; columnNumber-- )
				setCellValue( arguments.workbook, arguments.value, rowNumber, columnNumber );
		}
	}

	public void function setCellValue( required workbook, required value, required numeric row, required numeric column, string type ){
		var args = {
			workbook: arguments.workbook
			,cell: initializeCell( arguments.workbook, arguments.row, arguments.column )
			,value: arguments.value
		};
		if( arguments.KeyExists( "type" ) )
			args.type = arguments.type;
		setCellValueAsType( argumentCollection=args );
	}

	public void function setColumnWidth( required workbook, required numeric column, required numeric width ){
		var columnIndex = ( arguments.column -1 );
		getActiveSheet( arguments.workbook ).setColumnWidth( JavaCast( "int", columnIndex ), JavaCast( "int", ( arguments.width * 256 ) ) );
	}

	public void function setFitToPage( required workbook, required boolean state, numeric pagesWide, numeric pagesHigh ){
		var sheet = getActiveSheet( arguments.workbook );
		sheet.setFitToPage( JavaCast( "boolean", arguments.state ) );
		sheet.setAutoBreaks( JavaCast( "boolean", arguments.state ) ); //seems dependent on this matching
		if( !arguments.state )
			return;
		if( arguments.KeyExists( "pagesWide" ) && IsValid( "integer", arguments.pagesWide ) )
			sheet.getPrintSetup().setFitWidth( JavaCast( "short", arguments.pagesWide ) );
		if( arguments.KeyExists( "pagesWide" ) && IsValid( "integer", arguments.pagesHigh ) )
			sheet.getPrintSetup().setFitHeight( JavaCast( "short", arguments.pagesHigh ) );
	}

	public void function setFooter(
		required workbook
		,string leftFooter=""
		,string centerFooter=""
		,string rightFooter=""
	){
		var footer = getActiveSheetFooter( arguments.workbook );
		if( arguments.centerFooter.Len() )
			footer.setCenter( JavaCast( "string", arguments.centerFooter ) );
		if( arguments.leftFooter.Len() )
			footer.setleft( JavaCast( "string", arguments.leftFooter ) );
		if( arguments.rightFooter.Len() )
			footer.setright( JavaCast( "string", arguments.rightFooter ) );
	}

	public void function setFooterImage(
		required workbook
		,required string position // left|center|right
		,required any image
		,string imageType
	){
		setHeaderOrFooterImage( argumentCollection=arguments, isHeader=false );
	}

	public void function setHeader(
		required workbook
		,string leftHeader=""
		,string centerHeader=""
		,string rightHeader=""
	){
		var header = getActiveSheetHeader( arguments.workbook );
		if( arguments.centerHeader.Len() )
			header.setCenter( JavaCast( "string", arguments.centerHeader ) );
		if( arguments.leftHeader.Len() )
			header.setleft( JavaCast( "string", arguments.leftHeader ) );
		if( arguments.rightHeader.Len() )
			header.setright( JavaCast( "string", arguments.rightHeader ) );
	}

	public void function setHeaderImage(
		required workbook
		,required string position // left|center|right
		,required any image
		,string imageType
	){
		setHeaderOrFooterImage( argumentCollection=arguments );
	}

	public void function setReadOnly( required workbook, required string password ){
		if( isXmlFormat( arguments.workbook ) )
			Throw( type=this.getExceptionType(), message="setReadOnly not supported for XML workbooks", detail="The setReadOnly() method only works on binary 'xls' workbooks." );
		// writeProtectWorkbook takes both a user name and a password, just making up a user name
		arguments.workbook.writeProtectWorkbook( JavaCast( "string", arguments.password ), JavaCast( "string", "user" ) );
	}

	public void function setRecalculateFormulasOnNextOpen( required workbook, boolean value=true ){
		arguments.workbook.setForceFormulaRecalculation( JavaCast( "boolean", arguments.value ) );
	}

	public void function setRepeatingColumns( required workbook, required string columnRange ){
		arguments.columnRange = arguments.columnRange.Trim();
		if( !IsValid( "regex", arguments.columnRange,"[A-Za-z]:[A-Za-z]" ) )
			Throw( type=this.getExceptionType(), message="Invalid columnRange argument", detail="The 'columnRange' argument should be in the form 'A:B'" );
		var cellRangeAddress = getCellRangeAddressFromReference( arguments.columnRange );
		getActiveSheet( arguments.workbook ).setRepeatingColumns( cellRangeAddress );
	}

	public void function setRepeatingRows( required workbook, required string rowRange ){
		arguments.rowRange = arguments.rowRange.Trim();
		if( !IsValid( "regex", arguments.rowRange,"\d+:\d+" ) )
			Throw( type=this.getExceptionType(), message="Invalid rowRange argument", detail="The 'rowRange' argument should be in the form 'n:n', e.g. '1:5'" );
		var cellRangeAddress = getCellRangeAddressFromReference( arguments.rowRange );
		getActiveSheet( arguments.workbook ).setRepeatingRows( cellRangeAddress );
	}

	public void function setRowHeight( required workbook, required numeric row, required numeric height ){
		getRowFromActiveSheet( arguments.workbook, arguments.row ).setHeightInPoints( JavaCast( "int", arguments.height ) );
	}

	public void function setSheetTopMargin( required workbook, required numeric marginSize, string sheetName, numeric sheetNumber ){
		var sheet = getSpecifiedOrActiveSheet( argumentCollection=arguments );
		sheet.setMargin( sheet.TopMargin, arguments.marginSize );
	}

	public void function setSheetBottomMargin( required workbook, required numeric marginSize, string sheetName, numeric sheetNumber ){
		var sheet = getSpecifiedOrActiveSheet( argumentCollection=arguments );
		sheet.setMargin( sheet.BottomMargin, arguments.marginSize );
	}

	public void function setSheetLeftMargin( required workbook, required numeric marginSize, string sheetName, numeric sheetNumber ){
		var sheet = getSpecifiedOrActiveSheet( argumentCollection=arguments );
		sheet.setMargin( sheet.LeftMargin, arguments.marginSize );
	}

	public void function setSheetRightMargin( required workbook, required numeric marginSize, string sheetName, numeric sheetNumber ){
		var sheet = getSpecifiedOrActiveSheet( argumentCollection=arguments );
		sheet.setMargin( sheet.RightMargin, arguments.marginSize );
	}

	public void function setSheetHeaderMargin( required workbook, required numeric marginSize, string sheetName, numeric sheetNumber ){
		var sheet = getSpecifiedOrActiveSheet( argumentCollection=arguments );
		sheet.setMargin( sheet.HeaderMargin, arguments.marginSize );
	}

	public void function setSheetFooterMargin( required workbook, required numeric marginSize, string sheetName, numeric sheetNumber ){
		var sheet = getSpecifiedOrActiveSheet( argumentCollection=arguments );
		sheet.setMargin( sheet.FooterMargin, arguments.marginSize );
	}

	public void function setSheetPrintOrientation( required workbook, required string mode, string sheetName, numeric sheetNumber ){
		if( !ListFindNoCase( "landscape,portrait", arguments.mode ) )
			Throw( type=this.getExceptionType(), message="Invalid mode argument", detail="#mode# is not a valid 'mode' argument. Use 'portrait' or 'landscape'" );
		var setToLandscape = ( LCase( arguments.mode ) == "landscape" );
		var sheet = getSpecifiedOrActiveSheet( argumentCollection=arguments );
		sheet.getPrintSetup().setLandscape( JavaCast( "boolean", setToLandscape ) );
	}

	public void function shiftColumns( required workbook, required numeric start, numeric end=arguments.start, numeric offset=1 ){
		/*
			20210427 POI 4.x's sheet.shiftColumns() doesn't seem to work reliably: XSSF version doesn't delete columns that should be replaced. Both result in errors when writing
		*/
		if( arguments.start <= 0 )
			Throw( type=this.getExceptionType(), message="Invalid start value", detail="The start value must be greater than or equal to 1" );
		if( arguments.KeyExists( "end" ) && ( ( arguments.end <= 0 ) || ( arguments.end < arguments.start ) ) )
			Throw( type=this.getExceptionType(), message="Invalid end value", detail="The end value must be greater than or equal to the start value" );
		var rowIterator = getActiveSheet( arguments.workbook ).rowIterator();
		var startIndex = ( arguments.start -1 );
		var endIndex = arguments.KeyExists( "end" )? ( arguments.end -1 ): startIndex;
		while( rowIterator.hasNext() ){
			var row = rowIterator.next();
			if( arguments.offset > 0 ){
				for( var i = endIndex; i >= startIndex; i-- )
					shiftCell( arguments.workbook, row, i, arguments.offset );
			}
			else{
				for( var i = startIndex; i <= endIndex; i++ )
					shiftCell( arguments.workbook, row, i, arguments.offset );
			}
		}
	}

	public void function shiftRows( required workbook, required numeric start, numeric end=arguments.start, numeric offset=1 ){
		getActiveSheet( arguments.workbook ).shiftRows(
			JavaCast( "int", ( arguments.start - 1 ) )
			,JavaCast( "int", ( arguments.end - 1 ) )
			,JavaCast( "int", arguments.offset )
		);
	}

	public void function showColumn( required workbook, required numeric column ){
		toggleColumnHidden( arguments.workbook, arguments.column, false );
	}

	public void function showRow( required workbook, required numeric row ){
		toggleRowHidden( arguments.workbook, arguments.row, false );
	}

	public void function write(
		required workbook
		,required string filepath
		,boolean overwrite=false
		,string password
		,string algorithm="agile"
	){
		if( !arguments.overwrite && FileExists( arguments.filepath ) )
			throwFileExistsException( arguments.filepath );
		var passwordProtect = ( arguments.KeyExists( "password" ) && !arguments.password.Trim().IsEmpty() );
		if( passwordProtect && isBinaryFormat( arguments.workbook ) )
			Throw( type=this.getExceptionType(), message="Whole file password protection is not supported for binary workbooks", detail="Password protection only works with XML ('xlsx') workbooks." );
		try{
			lock name="#arguments.filepath#" timeout=5{
				var outputStream = CreateObject( "java", "java.io.FileOutputStream" ).init( arguments.filepath );
				arguments.workbook.write( outputStream );
				outputStream.flush();
			}
		}
		finally{
			// always close the stream. otherwise file may be left in a locked state if an unexpected error occurs
			closeLocalFileOrStream( local, "outputStream" );
			cleanUpStreamingXml( arguments.workbook );
		}
		if( passwordProtect )
			encryptFile( arguments.filepath, arguments.password, arguments.algorithm );
	}

	public void function writeToCsv(
		required workbook
		,required string filepath
		,boolean overwrite=false
		,string delimiter=","
		,boolean includeHeaderRow=true
		,numeric headerRow=1
	){
		if( !arguments.overwrite && FileExists( arguments.filepath ) )
			throwFileExistsException( arguments.filepath );
		var data = sheetToQuery(
			workbook=arguments.workbook
			,headerRow=arguments.headerRow
			,includeHeaderRow=arguments.includeHeaderRow
			,makeColumnNamesSafe=true //doesn't affect the output: avoids ACF clunky workaround in _QueryNew()
		);
		var csv = queryToCsv( query=data, delimiter=arguments.delimiter );
		FileWrite( arguments.filepath, csv );
	}

	/* END PUBLIC API */

	/* PRIVATE METHODS */

	/* Class loading */
	private array function getJarPaths(){
		var libPath = GetDirectoryFromPath( GetCurrentTemplatePath() ) & "lib/";
		return DirectoryList( libPath );
	}

	private function loadClass( required string javaclass ){
		if( this.getRequiresJavaLoader() )
			return loadClassUsingJavaLoader( arguments.javaclass );
		if( !IsNull( this.getOsgiLoader() ) )
			return loadClassUsingOsgi( arguments.javaclass );
		// If ACF and not using JL, *the correct* POI jars must be in the class path and any older versions *removed*
		try{
			this.setJavaClassesLastLoadedVia( "The java class path" );
			return CreateObject( "java", arguments.javaclass );
		}
		catch( any exception ){
			return loadClassUsingJavaLoader( arguments.javaclass );
		}
	}

	private function loadClassUsingJavaLoader( required string javaclass ){
		if( !server.KeyExists( this.getJavaLoaderName() ) )
			server[ this.getJavaLoaderName() ] = CreateObject( "component", this.getJavaLoaderDotPath() ).init( loadPaths=getJarPaths(), loadColdFusionClassPath=false, trustedSource=true );
		this.setJavaClassesLastLoadedVia( "JavaLoader" );
		return server[ this.getJavaLoaderName() ].create( arguments.javaclass );
	}

	private function loadClassUsingOsgi( required string javaclass ){
		this.setJavaClassesLastLoadedVia( "OSGi bundle" );
		return this.getOsgiLoader().loadClass(
			className: arguments.javaclass
			,bundlePath: GetDirectoryFromPath( GetCurrentTemplatePath() ) & "/lib-osgi.jar"
			,bundleSymbolicName: this.getOsgiLibBundleSymbolicName()
			,bundleVersion: this.getOsgiLibBundleVersion()
		);
	}

	private void function dumpPathToClassNoOsgi( required string className ){
		var classLoader = loadClass( arguments.className ).getClass().getClassLoader();
		var path = classLoader.getResource( arguments.className.Replace( ".", "/", "all" ) & ".class" ).getPath();
		WriteDump( path );
	}

	/* Files */

	private void function downloadBinaryVariable( required binaryVariable, required string filename, required contentType ){
		cfheader( name="Content-Disposition", value='attachment; filename="#arguments.filename#"' );
		cfcontent( type=arguments.contentType, variable="#arguments.binaryVariable#", reset="true" );
	}

	private void function encryptFile( required string filepath, required string password, required string algorithm ){
		// See https://poi.apache.org/encryption.html
		// NB: Not all spreadsheet programs support this type of encryption
		// set up the encryptor with the chosen algo
		var validAlgorithms = [ "agile", "standard", "binaryRC4" ];
		if( !ArrayFindNoCase( validAlgorithms, arguments.algorithm ) )
			Throw( type=this.getExceptionType(), message="Invalid algorithm", detail="'#arguments.algorithm#' is not a valid algorithm. Supported algorithms are: #validAlgorithms.ToList( ', ')#" );
		lock name="#arguments.filepath#" timeout=5 {
			var mode = loadClass( "org.apache.poi.poifs.crypt.EncryptionMode" );
			var info = loadClass( "org.apache.poi.poifs.crypt.EncryptionInfo" ).init( mode[ arguments.algorithm ] );
			var encryptor = info.getEncryptor();
			encryptor.confirmPassword( JavaCast( "string", arguments.password ) );
			try{
				// set up a POI filesystem object
				var poifs = loadClass( "org.apache.poi.poifs.filesystem.POIFSFileSystem" );
				try{
					// set up an encrypted stream within the POI filesystem
					// ACF gets confused by encryptor.getDataStream( POIFSFileSystem ) signature. Using getRoot() means getDataStream( DirectoryNode ) will be used
					if( this.getIsACF() )
						var encryptedStream = encryptor.getDataStream( poifs.getRoot() );
					else
						var encryptedStream = encryptor.getDataStream( poifs );
					// read in the unencrypted wb file and write it to the encrypted stream
					var workbook = workbookFromFile( arguments.filepath );
					workbook.write( encryptedStream );
				}
				finally{
					// make sure encrypted stream in closed
					closeLocalFileOrStream( local, "encryptedStream" );
				}
				try{
					// write the encrypted POI filesystem to file, replacing the unencypted version
					var outputStream = CreateObject( "java", "java.io.FileOutputStream" ).init( arguments.filepath );
					poifs.writeFilesystem( outputStream );
					outputStream.flush();
				}
				finally{
					// always close the stream. otherwise file may be left in a locked state if an unexpected error occurs
					closeLocalFileOrStream( local, "outputStream" );
				}
			}
			finally{
				closeLocalFileOrStream( local, "poifs" );
			}
		}
	}

	private void function closeLocalFileOrStream( required localScope, required string varName ){
		if( arguments.localScope.KeyExists( arguments.varName ) )
			arguments.localScope[ arguments.varName ].close();
	}

	private string function filenameSafe( required string input ){
		var charsToRemove	=	"\|\\\*\/\:""<>~&";
		var result = arguments.input.reReplace( "[#charsToRemove#]+", "", "ALL" ).Left( 255 );
		if( result.IsEmpty() )
			return "renamed"; // in case all chars have been replaced (unlikely but possible)
		return result;
	}

	private string function getFileContentTypeFromPath( required string path ){
		try{
			return FileGetMimeType( arguments.path, true ).ListLast( "/" );
		}
		catch( any exception ){
			return "unknown";
		}
	}

	private void function handleInvalidSpreadsheetFile( required string path ){
		var detail = "The file #arguments.path# does not appear to be a binary or xml spreadsheet.";
		if( isCsvTsvOrTextFile( arguments.path ) )
			detail &= " It may be a CSV/TSV file, in which case use 'csvToQuery()' to read it";
		Throw( type="cfsimplicity.lucee.spreadsheet.invalidFile", message="Invalid spreadsheet file", detail=detail );
	}

	private boolean function isCsvTsvOrTextFile( required string path ){
		var contentType = getFileContentTypeFromPath( arguments.path );
		return ListFindNoCase( "csv,tab-separated-values,plain", contentType );//Lucee=text/plain ACF=text/csv tsv=text/tab-separated-values
	}

	private void function throwErrorIFfileNotExists( required string path ){
		if( !FileExists( arguments.path ) )
			throwNonExistentFileException( arguments.path );
	}

	private void function throwErrorIFnotCsvOrTextFile( required string path ){
		if( !isCsvTsvOrTextFile( arguments.path ) )
			Throw( type=this.getExceptionType(), message="Invalid csv file", detail="#arguments.path# does not appear to be a csv/tsv/text file" );
	}

	/* Images */

	private numeric function addImageToWorkbook(
		required workbook
		,required any image //path or object
		,string imageType
	){
		// TODO image objects don't always work, depending on how they're created: POI accepts it but the image is not displayed (broken)
		var imageArgumentIsObject = IsImage( arguments.image );
		if( imageArgumentIsObject && !arguments.KeyExists( "imageType" ) )
			Throw( type=this.getExceptionType(), message="Invalid argument combination", detail="If you specify an image object, you must also provide the imageType argument" );
		var imageArgumentIsFile = ( !imageArgumentIsObject && IsSimpleValue( arguments.image ) && FileExists( arguments.image ) );
		if( !imageArgumentIsObject && IsSimpleValue( arguments.image ) && !imageArgumentIsFile )
			throwNonExistentFileException( arguments.image );
		if( !imageArgumentIsObject && !imageArgumentIsFile )
			Throw( type=this.getExceptionType(), message="Invalid image", detail="You must provide either a file path or an image object" );
		if( imageArgumentIsFile ){
			arguments.imageType = getFileContentTypeFromPath( arguments.image );
			if( arguments.imageType == "unknown" )
				throwUnknownImageTypeException();
		}
		var imageTypeIndex = getImageTypeIndex( arguments.workbook, arguments.imageType );
		var bytes = imageArgumentIsFile? FileReadBinary( arguments.image ): ToBinary( ToBase64( arguments.image ) );
		return arguments.workbook.addPicture( bytes, JavaCast( "int", imageTypeIndex ) );// returns 1-based integer index
	}

	private numeric function getImageTypeIndex( required workbook, required string imageType ){
		switch( arguments.imageType ){
			case "DIB": case "EMF": case "JPEG": case "PICT": case "PNG": case "WMF":
				return arguments.workbook[ "PICTURE_TYPE_" & arguments.imageType.UCase() ];
			case "JPG":
				return arguments.workbook.PICTURE_TYPE_JPEG;
		}
		Throw( type=this.getExceptionType(), message="Invalid Image Type", detail="Valid image types are DIB, EMF, JPG, JPEG, PICT, PNG, and WMF" );
	}

	/* Header/Footer images */

	//see https://stackoverflow.com/questions/51077404/apache-poi-adding-watermark-in-excel-workbook/51103756#51103756
	private void function setHeaderOrFooterImage(
		required workbook
		,required string position // left|center|right
		,required any image
		,string imageType
		,boolean isHeader=true //false = footer
	){
		var headerType = arguments.isHeader? "Header": "Footer";
		if( !isXmlFormat( arguments.workbook ) )
			Throw( type=this.getExceptionType(), message="Invalid spreadsheet type", detail="#headerType# images can only be added to XLSX spreadsheets." );
		var imageIndex = addImageToWorkbook( argumentCollection=arguments );
		var sheet = getActiveSheet( arguments.workbook );
		var headerObject = arguments.isHeader? sheet.getHeader(): sheet.getFooter();
		var headerTypeInitialLetter = headerType.Left( 1 ); // "H" or "F"
		var headerImagePartName = "/xl/drawings/vmlDrawing1.vml";
		switch( arguments.position ){
			case "left": case "l":
				headerObject.setLeft( "&G" ); //&G means Graphic
				var vmlPosition = "L#headerTypeInitialLetter#";
				break;
			case "center": case "c": case "centre":
				headerObject.setCenter( "&G" );
				var vmlPosition = "C#headerTypeInitialLetter#";
				break;
			case "right": case "r":
				headerObject.setRight( "&G" );
				var vmlPosition = "R#headerTypeInitialLetter#";
				break;
			default: Throw( type=this.getExceptionType(), message="Invalid #headerType.LCase()# position", detail="The 'position' argument '#arguments.position#' is invalid. Use 'left', 'center' or 'right'" );
		}
		// check for existing header/footer images
		var existingRelation = getExistingHeaderFooterImageRelation( sheet, headerImagePartName );
		var sheetHasExistingHeaderFooterImages = local.KeyExists( "existingRelation" );
		if( sheetHasExistingHeaderFooterImages ){
			var part = existingRelation.getPackagePart();
			try{
				var headerImageXML = existingRelation.getXml();//Works OK if workbook not previously saved with header/footer images
			}
			catch( any exception ){
				if( exception.message.Find( "getXml" ) )
					// ...but won't work if file has been previously saved with a header/footer image
					Throw( type=this.getExceptionType(), message="Spreadsheet contains an existing header or footer", detail="Header/footer images can't currently be added to spreadsheets read from disk that already have them." );
					/*
						TODO why won't this work? This is how to get the existing xml, but it won't save back modified to the vmlDrawing1.vml part for some reason
						headerImageXML = sheet.getRelations()[ i ].getDocument().xmlText();
					*/
				else
					rethrow;
			}
		}
		else{
			var OPCPackage = workbook.getPackage();
			var partName = loadClass( "org.apache.poi.openxml4j.opc.PackagingURIHelper" ).createPartName( headerImagePartName );
			var part = OPCPackage.createPart( partName, "application/vnd.openxmlformats-officedocument.vmlDrawing" );
			var headerImageXML = getNewHeaderImageXML();
		}
		var headerImageVml = loadClass( "luceeSpreadsheet.HeaderImageVML" ).init( part );
		//create the relation to the picture
		var pictureData = arguments.workbook.getAllPictures().get( imageIndex );
		var xssfImageRelation = loadClass( "org.apache.poi.xssf.usermodel.XSSFRelation" ).IMAGES;
		var pictureRelationID = headerImageVml.addRelation( JavaCast( "null", 0 ), xssfImageRelation, pictureData ).getRelationship().getId();
		//get image dimension
		try{
			var imageInputStream = CreateObject( "java", "java.io.ByteArrayInputStream" ).init( pictureData.getData() );
			var imageUtils = loadClass( "org.apache.poi.ss.util.ImageUtils" );
			var imageDimension = imageUtils.getImageDimension( imageInputStream, pictureData.getPictureType() );
		}
		catch( any exception ){
			rethrow;
		}
		finally{
			closeLocalFileOrStream( local, "imageInputStream" );
		}
		var newShapeElement = createNewHeaderImageVMLShape( pictureRelationID, vmlPosition, imageDimension );
		headerImageXML = headerImageXML.ReReplaceNoCase( "(<\/[\w:]*xml>)", newShapeElement & "\1" );
		headerImageVml.setXml( headerImageXML );
	  //create the sheet/vml relation
	  var xssfVmlRelation = loadClass( "org.apache.poi.xssf.usermodel.XSSFRelation" ).VML_DRAWINGS;
  	var sheetVmlRelationID = sheet.addRelation( JavaCast( "null", 0 ), xssfVmlRelation, headerImageVml ).getRelationship().getId();
  	//create the <legacyDrawingHF r:id="..."/> in /xl/worksheets/sheetN.xml
  	if( !sheetHasExistingHeaderFooterImages )
  		sheet.getCTWorksheet().addNewLegacyDrawingHF().setId( sheetVmlRelationID );
	}

	private any function getExistingHeaderFooterImageRelation( required sheet, required string headerImagePartName ){
		var totalExistingRelations = arguments.sheet.getRelations().Len();
		if( totalExistingRelations == 0 )
			return;
		cfloop( from=1, to=totalExistingRelations, index="local.i" ){
			var relation = arguments.sheet.getRelations()[ i ];
			if( relation.getPackagePart().getPartName().getName() == arguments.headerImagePartName )
				return relation;
		}	
	}

	private string function createNewHeaderImageVMLShape( required string pictureRelationID, required string vmlPosition, required imageDimension ){
		return Trim( '
			<v:shape id="#arguments.vmlPosition#" o:spid="_x0000_s1025" type="##_x0000_t75" style="position:absolute;margin:0;width:#arguments.imageDimension.getWidth()#pt;height:#arguments.imageDimension.getHeight()#pt;">
				<v:imagedata o:relid="#pictureRelationID#" o:title="#pictureRelationID#" />
				<o:lock v:ext="edit" rotation="t" />
			</v:shape>
		' ).REReplace( ">\s+<", "><", "ALL" );
	}

	private string function getNewHeaderImageXML(){
		return '<xml xmlns:v="urn:schemas-microsoft-com:vml" xmlns:o="urn:schemas-microsoft-com:office:office" xmlns:x="urn:schemas-microsoft-com:office:excel"><o:shapelayout v:ext="edit"><o:idmap v:ext="edit" data="1" /></o:shapelayout><v:shapetype id="_x0000_t75" coordsize="21600,21600" o:spt="75" o:preferrelative="t" path="m@4@5l@4@11@9@11@9@5xe" filled="f" stroked="f"><v:stroke joinstyle="miter" /><v:formulas><v:f eqn="if lineDrawn pixelLineWidth 0" /><v:f eqn="sum @0 1 0" /><v:f eqn="sum 0 0 @1" /><v:f eqn="prod @2 1 2" /><v:f eqn="prod @3 21600 pixelWidth" /><v:f eqn="prod @3 21600 pixelHeight" /><v:f eqn="sum @0 0 1" /><v:f eqn="prod @6 1 2" /><v:f eqn="prod @7 21600 pixelWidth" /><v:f eqn="sum @8 21600 0" /><v:f eqn="prod @7 21600 pixelHeight" /><v:f eqn="sum @10 21600 0" /></v:formulas><v:path o:extrusionok="f" gradientshapeok="t" o:connecttype="rect" /><o:lock v:ext="edit" aspectratio="t" /></v:shapetype></xml>';
	}

	/* Workbooks */

	private any function createWorkBook(
		required string sheetName
		,boolean xmlFormat=false
		,boolean streamingXml=false
		,numeric streamingWindowSize=100
	){
		validateSheetName( arguments.sheetName );
		if( !arguments.xmlFormat )
			return loadClass( this.getHSSFWorkbookClassName() ).init();
		if( !arguments.streamingXml )
			return loadClass( this.getXSSFWorkbookClassName() ).init();
		if( !IsValid( "integer", arguments.streamingWindowSize ) || ( arguments.streamingWindowSize < 1 ) )
			Throw( type=this.getExceptionType(), message="Invalid 'streamingWindowSize' argument", detail="'streamingWindowSize' must be an integer value greater than 1" );
		return loadClass( this.getSXSSFWorkbookClassName() ).init( JavaCast( "int", arguments.streamingWindowSize ) );
	}

	private any function workbookFromFile( required string path, string password ){
		// works with both xls and xlsx
		// see https://stackoverflow.com/a/46149469 for why FileInputStream is preferable to File
		// 20210322 using File doesn't seem to improve memory usage anyway.
		lock name="#arguments.path#" timeout=5 {
			try{
				var factory = loadClass( "org.apache.poi.ss.usermodel.WorkbookFactory" );
				var file = CreateObject( "java", "java.io.FileInputStream" ).init( arguments.path );
				if( arguments.KeyExists( "password" ) )
					return factory.create( file, arguments.password );
				return factory.create( file );
			}
			catch( org.apache.poi.hssf.OldExcelFormatException exception ){
				throwOldExcelFormatException( arguments.path );
			}
			catch( any exception ){
				if( exception.message CONTAINS "unsupported file type" )
				handleInvalidSpreadsheetFile( arguments.path );// from POI 5.x
				if( exception.message CONTAINS "spreadsheet seems to be Excel 5" )
					throwOldExcelFormatException( arguments.path );
				rethrow;
			}
			finally{
				closeLocalFileOrStream( local, "file" );
			}
		}
	}

	/* Sheets */

	private void function deleteSheetAtIndex( required workbook, required numeric sheetIndex ){
		arguments.workbook.removeSheetAt( JavaCast( "int", arguments.sheetIndex ) );
	}

	private string function generateUniqueSheetName( required workbook ){
		var startNumber = ( arguments.workbook.getNumberOfSheets() +1 );
		var maxRetry = ( startNumber +250 );
		for( var sheetNumber = startNumber; sheetNumber <= maxRetry; sheetNumber++ ){
			var proposedName = "Sheet" & sheetNumber;
			if( !sheetExists( arguments.workbook, proposedName ) )
				return proposedName;
		}
		// this should never happen. but if for some reason it did, warn the action failed and abort
		Throw( type=this.getExceptionType(), message="Unable to generate name", detail="Unable to generate a unique sheet name" );
	}

	private any function getActiveSheet( required workbook ){
		return arguments.workbook.getSheetAt( JavaCast( "int", arguments.workbook.getActiveSheetIndex() ) );
	}

	private any function getActiveSheetFooter( required workbook ){
		return getActiveSheet( arguments.workbook ).getFooter();
	}

	private any function getActiveSheetHeader( required workbook ){
		return getActiveSheet( arguments.workbook ).getHeader();
	}

	private any function getActiveSheetName( required workbook ){
		return getActiveSheet( arguments.workbook ).getSheetName();
	}

	private void function setActiveSheetNameOrNumber( required workbook, required sheetNameOrNumber ){
		if( IsValid( "integer", arguments.sheetNameOrNumber ) && IsNumeric( arguments.sheetNameOrNumber ) ){
			var sheetNumber = arguments.sheetNameOrNumber;
			setActiveSheetNumber( arguments.workbook, sheetNumber );
			return;
		}
		var sheetName = arguments.sheetNameOrNumber;
		setActiveSheet( arguments.workbook, sheetName );
	}

	private array function getAllSheetFormulas( required workbook ){
		var rowIterator = getActiveSheet( arguments.workbook ).rowIterator();
		var formulas = [];
		while( rowIterator.hasNext() ){
			var cellIterator = rowIterator.next().cellIterator();
			while( cellIterator.hasNext() ){
				var cell = cellIterator.next();
				var formulaStruct = {
					row: ( cell.getRowIndex() + 1 )
					,column: ( cell.getColumnIndex() + 1 )
				};
				try{
					formulaStruct.formula = cell.getCellFormula();
				}
				catch( any exception ){
					formulaStruct.formula = "";
				}
				if( formulaStruct.formula.Len() )
					formulas.Append( formulaStruct );
			}
		}
		return formulas;
	}

	private any function getSheetByName( required workbook, required string sheetName ){
		validateSheetExistsWithName( arguments.workbook, arguments.sheetName );
		return arguments.workbook.getSheet( JavaCast( "string", arguments.sheetName ) );
	}

	private any function getSheetByNumber( required workbook, required numeric sheetNumber ){
		validateSheetNumber( arguments.workbook, arguments.sheetNumber );
		var sheetIndex = ( arguments.sheetNumber -1 );
		return arguments.workbook.getSheetAt( sheetIndex );
	}

	private any function getSpecifiedOrActiveSheet( required workbook, string sheetName, numeric sheetNumber ){
		throwErrorIFSheetNameAndNumberArgumentsBothPassed( argumentCollection=arguments );
		if( !sheetNameArgumentWasProvided( argumentCollection=arguments ) && !sheetNumberArgumentWasProvided( argumentCollection=arguments ) )
			return getActiveSheet( arguments.workbook );
		if( sheetNameArgumentWasProvided( argumentCollection=arguments ) )
			return getSheetByName( arguments.workbook, arguments.sheetName );
		return getSheetByNumber( arguments.workbook, arguments.sheetNumber );
	}

	private numeric function getSheetIndexFromName( required workbook, required string sheetName ){
		//returns -1 if non-existent
		return arguments.workbook.getSheetIndex( JavaCast( "string", arguments.sheetName ) );
	}

	private void function moveSheet( required workbook, required string sheetName, required string moveToIndex ){
		arguments.workbook.setSheetOrder( JavaCast( "String", arguments.sheetName ), JavaCast( "int", arguments.moveToIndex ) );
	}

	private boolean function sheetExists( required workbook, string sheetName, numeric sheetNumber ){
		validateSheetNameOrNumberWasProvided( argumentCollection=arguments );
		if( arguments.KeyExists( "sheetName" ) )
			arguments.sheetNumber = ( getSheetIndexFromName( arguments.workbook, arguments.sheetName ) +1 );
			//the position is valid if it's an integer between 1 and the total number of sheets in the workbook
		if( arguments.sheetNumber && ( arguments.sheetNumber == Round( arguments.sheetNumber ) ) && ( arguments.sheetNumber <= arguments.workbook.getNumberOfSheets() ) )
			return true;
		return false;
	}

	private boolean function sheetHasMergedRegions( required sheet ){
		return ( arguments.sheet.getNumMergedRegions() > 0 );
	}

	private query function sheetToQuery(
		required workbook
		,string sheetName
		,numeric sheetNumber=1
		,numeric headerRow
		,boolean includeHeaderRow=false
		,boolean includeBlankRows=false
		,boolean includeHiddenColumns=false
		,boolean fillMergedCellsWithVisibleValue=false
		,boolean includeRichTextFormatting=false
		,string rows //range
		,string columns //range
		,any columnNames //list or array
		,any queryColumnTypes="" //'auto', single default type e.g. 'VARCHAR', or list of types, or struct of column names/types mapping. Empty means no types are specified.
		,boolean makeColumnNamesSafe=false
	){
		var sheet = {
			includeHeaderRow: arguments.includeHeaderRow
			,hasHeaderRow: ( arguments.KeyExists( "headerRow" ) && Val( arguments.headerRow ) )
			,includeBlankRows: arguments.includeBlankRows
			,columnNames: []
			,columnRanges: []
			,totalColumnCount: 0
		};
		sheet.headerRowIndex = sheet.hasHeaderRow? ( arguments.headerRow -1 ): -1;
		if( arguments.KeyExists( "columns" ) ){
			sheet.columnRanges = extractRanges( arguments.columns );
			sheet.totalColumnCount = columnCountFromRanges( sheet.columnRanges );
		}
		if( arguments.KeyExists( "sheetName" ) ){
			validateSheetExistsWithName( arguments.workbook, arguments.sheetName );
			arguments.sheetNumber = ( getSheetIndexFromName( arguments.workbook, arguments.sheetName ) +1 );
		}
		sheet.object = getSheetByNumber( arguments.workbook, arguments.sheetNumber );
		if( arguments.fillMergedCellsWithVisibleValue )
			doFillMergedCellsWithVisibleValue( arguments.workbook, sheet.object );
		sheet.data = [];
		if( arguments.KeyExists( "rows" ) ){
			var allRanges = extractRanges( arguments.rows );
			for( var thisRange in allRanges ){
				for( var rowNumber = thisRange.startAt; rowNumber <= thisRange.endAt; rowNumber++ ){
					var rowIndex = ( rowNumber -1 );
					addRowToSheetData( arguments.workbook, sheet, rowIndex, arguments.includeRichTextFormatting );
				}
			}
		}
		else{
			var lastRowIndex = sheet.object.getLastRowNum();// zero based
			for( var rowIndex = 0; rowIndex <= lastRowIndex; rowIndex++ )
				addRowToSheetData( arguments.workbook, sheet, rowIndex, arguments.includeRichTextFormatting );
		}
		//generate the query columns
		if( arguments.KeyExists( "columnNames" ) && arguments.columnNames.Len() )
			sheet.columnNames = IsArray( arguments.columnNames )? arguments.columnNames: arguments.columnNames.ListToArray();
		else if( sheet.hasHeaderRow ){
			// use specified header row values as column names
			var headerRowObject = sheet.object.getRow( JavaCast( "int", sheet.headerRowIndex ) );
			var rowData = getRowData( arguments.workbook, headerRowObject, sheet.columnRanges );
			var i = 1;
			for( var value in rowData ){
				var columnName = "column" & i;
				if( isString( value ) && value.Len() )
					columnName = value;
				sheet.columnNames.Append( columnName );
				i++;
			}
		}
		else{
			for( var i=1; i <= sheet.totalColumnCount; i++ )
				sheet.columnNames.Append( "column" & i );
		}
		arguments.queryColumnTypes = parseQueryColumnTypesArgument( arguments.queryColumnTypes, sheet.columnNames, sheet.totalColumnCount, sheet.data );
		var result = _QueryNew( sheet.columnNames, arguments.queryColumnTypes, sheet.data, arguments.makeColumnNamesSafe );
		if( !arguments.includeHiddenColumns ){
			result = deleteHiddenColumnsFromQuery( sheet, result );
			if( sheet.totalColumnCount == 0 )
			return QueryNew( "" );// all columns were hidden: return a blank query.
		}
		return result;
	}

	private void function validateSheetExistsWithName( required workbook, required string sheetName ){
		if( !sheetExists( workbook=arguments.workbook, sheetName=arguments.sheetName ) )
			Throw( type=this.getExceptionType(), message="Invalid sheet name [#arguments.sheetName#]", detail="The specified sheet was not found in the current workbook." );
	}

	private void function validateSheetNumber( required workbook, required numeric sheetNumber ){
		if( !sheetExists( workbook=arguments.workbook, sheetNumber=arguments.sheetNumber ) ){
			var sheetCount = arguments.workbook.getNumberOfSheets();
			Throw( type=this.getExceptionType(), message="Invalid sheet number [#arguments.sheetNumber#]", detail="The sheetNumber must a whole number between 1 and the total number of sheets in the workbook [#sheetCount#]" );
		}
	}

	private void function validateSheetName( required string sheetName ){
		var characterCount = Len( arguments.sheetName );
		if( characterCount > 31 )
			Throw( type=this.getExceptionType(), message="Invalid sheet name", detail="The sheetname contains too many characters [#characterCount#]. The maximum is 31." );
		var poiTool = loadClass( "org.apache.poi.ss.util.WorkbookUtil" );
		try{
			poiTool.validateSheetName( JavaCast( "String", arguments.sheetName ) );
		}
		catch( "java.lang.IllegalArgumentException" exception ){
			Throw( type=this.getExceptionType(), message="Invalid characters in sheet name", detail=exception.message );
		}
		catch( "java.lang.reflect.InvocationTargetException" exception ){
			//ACF
			Throw( type=this.getExceptionType(), message="Invalid characters in sheet name", detail=exception.message );
		}
	}

	private void function validateSheetNameOrNumberWasProvided(){
		throwErrorIFSheetNameAndNumberArgumentsBothMissing( argumentCollection=arguments );
		throwErrorIFSheetNameAndNumberArgumentsBothPassed( argumentCollection=arguments );
	}

	private void function throwErrorIFSheetNameAndNumberArgumentsBothMissing(){
		if( !sheetNameArgumentWasProvided( argumentCollection=arguments ) && !sheetNumberArgumentWasProvided( argumentCollection=arguments ) )
			Throw( type=this.getExceptionType(), message="Missing Required Argument", detail="Either sheetName or sheetNumber must be provided" );
	}

	private void function throwErrorIFSheetNameAndNumberArgumentsBothPassed(){
		if( sheetNameArgumentWasProvided( argumentCollection=arguments ) && sheetNumberArgumentWasProvided( argumentCollection=arguments ) )
			Throw( type=this.getExceptionType(), message="Invalid arguments", detail="Only one argument is allowed. Specify either a sheetName or sheetNumber, not both" );
	}

	private boolean function sheetNameArgumentWasProvided(){
		return ( arguments.KeyExists( "sheetName" ) && Len( arguments.sheetName ) );
	}

	private boolean function sheetNumberArgumentWasProvided(){
		return ( arguments.KeyExists( "sheetNumber" ) && Len( arguments.sheetNumber ) );
	}

	/* Rows */

	private void function addRowToSheetData(
		required workbook
		,required struct sheet
		,required numeric rowIndex
		,boolean includeRichTextFormatting=false
	){
		if( ( arguments.rowIndex == arguments.sheet.headerRowIndex ) && !arguments.sheet.includeHeaderRow )
			return;
		var rowData = [];
		var row = arguments.sheet.object.getRow( JavaCast( "int", arguments.rowIndex ) );
		if( IsNull( row ) ){
			if( arguments.sheet.includeBlankRows )
				arguments.sheet.data.Append( rowData );
			return;
		}
		if( rowIsEmpty( row ) && !arguments.sheet.includeBlankRows )
			return;
		rowData = getRowData( arguments.workbook, row, arguments.sheet.columnRanges, arguments.includeRichTextFormatting );
		arguments.sheet.data.Append( rowData );
		if( !arguments.sheet.columnRanges.Len() ){
			var rowColumnCount = row.getLastCellNum();
			arguments.sheet.totalColumnCount = Max( arguments.sheet.totalColumnCount, rowColumnCount );
		}
	}

	private any function createRow( required workbook, numeric rowNum=getNextEmptyRowNumber( arguments.workbook ), boolean overwrite=true ){
		// get existing row (if any)
		var sheet = getActiveSheet( arguments.workbook );
		var row = sheet.getRow( JavaCast( "int", arguments.rowNum ) );
		if( arguments.overwrite && !IsNull( row ) )
			sheet.removeRow( row ); // forcibly remove existing row and all cells
		if( arguments.overwrite || IsNull( sheet.getRow( JavaCast( "int", arguments.rowNum ) ) ) ){
			try{
				row = sheet.createRow( JavaCast( "int", arguments.rowNum ) );
			}
			catch( java.lang.IllegalArgumentException exception ){
				if( exception.message.FindNoCase( "Invalid row number (65536)" ) )
					Throw( type=this.getExceptionType(), message="Too many rows", detail="Binary spreadsheets are limited to 65535 rows. Consider using an XML format spreadsheet instead." );
				else
					rethrow;
			}
		}
		return row;
	}

	private numeric function getFirstRowNumber( required workbook ){
		var sheet = getActiveSheet( arguments.workbook );
		var firstRow = sheet.getFirstRowNum();
		if( ( firstRow == 0 ) && ( sheet.getPhysicalNumberOfRows() == 0 ) )
			return -1;
		return firstRow;
	}

	private numeric function getLastRowNumber( required workbook, sheet=getActiveSheet( arguments.workbook ) ){
		var lastRow = arguments.sheet.getLastRowNum();
		if( ( lastRow == 0 ) && ( arguments.sheet.getPhysicalNumberOfRows() == 0 ) )
			return -1; //The sheet is empty. Return -1 instead of 0
		return lastRow;
	}

	private numeric function getNextEmptyCellIndexFromRow( required row ){
		return arguments.row.getLastCellNum(); //getLastCellNum() = the last cell index +1
	}

	private numeric function getNextEmptyRowNumber( workbook ){
		return ( getLastRowNumber( arguments.workbook ) +1 );
	}

	private array function getRowData( required workbook, required row, array columnRanges=[], boolean includeRichTextFormatting=false ){
		var result = [];
		if( !arguments.columnRanges.Len() ){
			var columnRange = {
				startAt: 1
				,endAt: arguments.row.getLastCellNum()
			};
			arguments.columnRanges = [ columnRange ];
		}
		for( var thisRange in arguments.columnRanges ){
			for( var i = thisRange.startAt; i <= thisRange.endAt; i++ ){
				var colIndex = ( i-1 );
				var cell = arguments.row.GetCell( JavaCast( "int", colIndex ) );
				if( IsNull( cell ) ){
					result.Append( "" );
					continue;
				}
				var cellValue = getCellValueAsType( arguments.workbook, cell );
				if( arguments.includeRichTextFormatting && cellIsOfType( cell, "STRING" ) )
					cellValue = richStringCellValueToHtml( arguments.workbook, cell,cellValue );
				result.Append( cellValue );
			}
		}
		return result;
	}

	private any function getRowFromActiveSheet( required workbook, required numeric rowNumber ){
		var rowIndex = ( arguments.rowNumber-1 );
		return getActiveSheet( arguments.workbook ).getRow( JavaCast( "int", rowIndex ) );
	}

	private array function parseListDataToArray( required string line, required string delimiter, boolean handleEmbeddedCommas=true ){
		var elements = ListToArray( arguments.line, arguments.delimiter );
		var potentialQuotes = 0;
		arguments.line = ToString( arguments.line );
		if( ( arguments.delimiter == "," ) && arguments.handleEmbeddedCommas )
			potentialQuotes = arguments.line.ReplaceAll( "[^']", "" ).length();
		if( potentialQuotes <= 1 )
			return elements;
		//For ACF compatibility, find any values enclosed in single quotes and treat them as a single element.
		var currentValue = 0;
		var nextValue = "";
		var isEmbeddedValue = false;
		var values = [];
		var buffer = newJavaStringBuilder();
		var maxElements = ArrayLen( elements );
		for( var i = 1; i <= maxElements; i++ ) {
		  currentValue = Trim( elements[ i ] );
		  nextValue = i < maxElements ? elements[ i + 1 ] : "";
		  var isComplete = false;
		  var hasLeadingQuote = ( currentValue.Left( 1 ) == "'" );
		  var hasTrailingQuote = ( currentValue.Right( 1 ) == "'" );
		  var isFinalElement = ( i == maxElements );
		  if( hasLeadingQuote )
		  	isEmbeddedValue = true;
		  if( isEmbeddedValue && hasTrailingQuote )
		  	isComplete = true;
		  /* We are finished with this value if:
			  * no quotes were found OR
			  * it is the final value OR
			  * the next value is embedded in quotes
		  */
		  if( !isEmbeddedValue || isFinalElement || ( nextValue.Left( 1 ) == "'" ) )
		  	isComplete = true;
		  if( isEmbeddedValue || isComplete ){
			  // if this a partial value, append the delimiter
			  if( isEmbeddedValue && buffer.length() > 0 )
			  	buffer.Append( "," );
			  buffer.Append( elements[ i ] );
		  }
		  if( isComplete ){
			  var finalValue = buffer.toString();
			  var startAt = finalValue.indexOf( "'" );
			  var endAt = finalValue.lastIndexOf( "'" );
			  if( isEmbeddedValue && startAt >= 0 && endAt > startAt )
			  	finalValue = finalValue.substring( ( startAt +1 ), endAt );
			  values.Append( finalValue );
			  buffer.setLength( 0 );
			  isEmbeddedValue = false;
		  }
	  }
	  return values;
	}

	private boolean function rowIsEmpty( required row ){
		for( var i = arguments.row.getFirstCellNum(); i < arguments.row.getLastCellNum(); i++ ){
	    var cell = arguments.row.getCell( i );
	    if( !IsNull( cell ) && !cellIsOfType( cell, "BLANK" ) )
	    	return false;
	  }
	  return true;
	}

	private boolean function rowHasCells( required row ){
		return ( arguments.row.getLastCellNum() > 0 );
	}

	/* Columns */

	// underscore prefix because otherwise errors: "no matching function [autoSizeColumns]"
	private void function _autoSizeColumns( required workbook, required numeric startColumnNumber, required numeric endColumnNumber ){
		for( var i = startColumnNumber; i <= endColumnNumber; i++ )
			autoSizeColumn( arguments.workbook, i );
	}

	private numeric function columnCountFromRanges( required array ranges ){
		var result = 0;
		for( var thisRange in arguments.ranges ){
			for( var i = thisRange.startAt; i <= thisRange.endAt; i++ )
				result++;
		}
		return result;
	}

	private void function shiftColumnsRightStartingAt( required numeric cellIndex, required row, required workbook ){
		var lastCellIndex = arguments.row.getLastCellNum()-1;
		for( var i = lastCellIndex; i >= arguments.cellIndex; i-- )
			shiftCell( arguments.workbook, arguments.row, i, 1 );
	}

	/* Cells */

	private boolean function cellExists( required workbook, required numeric rowNumber, required numeric columnNumber ){
		var checkRow = getRowFromActiveSheet( arguments.workbook, arguments.rowNumber );
		var columnIndex = ( arguments.columnNumber -1 );
		return !IsNull( checkRow ) && !IsNull( checkRow.getCell( JavaCast( "int", columnIndex ) ) );
	}

	private boolean function cellIsOfType( required cell, required string type ){
		var cellType = arguments.cell.getCellType();
		return ObjectEquals( cellType, cellType[ arguments.type ] );
	}

	private any function createCell( required row, numeric cellNum=arguments.row.getLastCellNum(), overwrite=true ){
		// get existing cell (if any)
		var cell = arguments.row.getCell( JavaCast( "int", arguments.cellNum ) );
		if( arguments.overwrite && !IsNull( cell ) )
			arguments.row.removeCell( cell );// forcibly remove the existing cell
		if( arguments.overwrite || IsNull( cell ) )
			cell = arguments.row.createCell( JavaCast( "int", arguments.cellNum ) );// create a brand new cell
		return cell;
	}

	private any function getCellAt( required workbook, required numeric rowNumber, required numeric columnNumber ){
		if( !cellExists( argumentCollection=arguments ) )
			Throw( type=this.getExceptionType(), message="Invalid cell", detail="The requested cell [#arguments.rowNumber#,#arguments.columnNumber#] does not exist in the active sheet" );
		var columnIndex = ( arguments.columnNumber -1 );
		return getRowFromActiveSheet( arguments.workbook, arguments.rowNumber ).getCell( JavaCast( "int", columnIndex ) );
	}

	private any function getCellFormulaValue( required workbook, required cell ){
		var formulaEvaluator = arguments.workbook.getCreationHelper().createFormulaEvaluator();
		try{
			return getDataFormatter().formatCellValue( arguments.cell, formulaEvaluator );
		}
		catch( any exception ){
			Throw( type=this.getExceptionType(), message="Failed to run formula", detail="There is a problem with the formula in sheet #arguments.cell.getSheet().getSheetName()# row #( arguments.cell.getRowIndex() +1 )# column #( arguments.cell.getColumnIndex() +1 )#");
		}
	}

	private any function getCellRangeAddressFromColumnAndRowIndices(
		required numeric startRowIndex
		,required numeric endRowIndex
		,required numeric startColumnIndex
		,required numeric endColumnIndex
	){
		//index = 0 based
		return loadClass( "org.apache.poi.ss.util.CellRangeAddress" ).init(
			JavaCast( "int", arguments.startRowIndex )
			,JavaCast( "int", arguments.endRowIndex )
			,JavaCast( "int", arguments.startColumnIndex )
			,JavaCast( "int", arguments.endColumnIndex )
		);
	}

	private any function getCellRangeAddressFromReference( required string rangeReference ){
		/*
		rangeReference = usually a standard area ref (e.g. "B1:D8"). May be a single cell ref (e.g. "B5") in which case the result is a 1 x 1 cell range. May also be a whole row range (e.g. "3:5"), or a whole column range (e.g. "C:F")
		*/
		return loadClass( "org.apache.poi.ss.util.CellRangeAddress" ).valueOf( JavaCast( "String", arguments.rangeReference ) );
	}

	private any function getCellValueAsType( required workbook, required cell ){
		/*
		Get the value of the cell based on the data type. The thing to worry about here is cell formulas and cell dates. Formulas can be strange and dates are stored as numeric types. Here I will just grab dates as floats and formulas I will try to grab as numeric values.
		*/
		if( cellIsOfType( arguments.cell, "NUMERIC" ) ){
			// Get numeric cell data. This could be a standard number, could also be a date value.
			if( getDateUtil().isCellDateFormatted( arguments.cell ) ){
				var cellValue = arguments.cell.getDateCellValue();
				if( isTimeOnlyValue( cellValue ) )
					return getDataFormatter().formatCellValue( arguments.cell );//return as a time formatted string to avoid default epoch date 1899-12-31
				return cellValue;
			}
			return arguments.cell.getNumericCellValue();
		}
		if( cellIsOfType( arguments.cell, "FORMULA" ) )
			return getCellFormulaValue( arguments.workbook, arguments.cell );
		if( cellIsOfType( arguments.cell, "BOOLEAN" ) )
			return arguments.cell.getBooleanCellValue();
	 	if( cellIsOfType( arguments.cell, "BLANK" ) )
	 		return "";
		try{
			return arguments.cell.getStringCellValue();
		}
		catch( any exception ){
			return "";
		}
	}

	private any function initializeCell( required workbook, required numeric rowNumber, required numeric columnNumber ){
		//Automatically creates the cell if it does not exist, instead of throwing an error
		var rowIndex = JavaCast( "int", ( arguments.rowNumber -1 ) );
		var columnIndex = JavaCast( "int", ( arguments.columnNumber -1 ) );
		var rowObject = getCellUtil().getRow( rowIndex, getActiveSheet( arguments.workbook ) );
		var cellObject = getCellUtil().getCell( rowObject, columnIndex );
		return cellObject;
	}

	private void function setCellValueAsType( required workbook, required cell, required value, string type ){
		var validCellTypes = [ "string", "numeric", "date", "time", "boolean", "blank" ];
		if( !arguments.KeyExists( "type" ) ) //autodetect type
			arguments.type = detectValueDataType( arguments.value );
		else if( !validCellTypes.FindNoCase( arguments.type ) )
			Throw( type=this.getExceptionType(), message="Invalid data type: '#arguments.type#'", detail="The data type must be one of the following: #validCellTypes.ToList( ', ' )#." );
		/* Note: To properly apply date/number formatting:
			- cell type must be CELL_TYPE_NUMERIC (NB: POI5+ can't set cell types explicitly anymore: https://bz.apache.org/bugzilla/show_bug.cgi?id=63118 )
			- cell value must be applied as a java.util.Date or java.lang.Double (NOT as a string)
			- cell style must have a dataFormat (datetime values only)
 		*/
		switch( arguments.type ){
			case "numeric":
				arguments.cell.setCellValue( JavaCast( "double", Val( arguments.value ) ) );
				return;
			case "date": case "time":
				//handle empty strings which can't be treated as dates
				if( Trim( arguments.value ).IsEmpty() ){
					arguments.cell.setBlank(); //no need to set the value: it will be blank
					return;
				}
				var dateTimeValue = ParseDateTime( arguments.value );
				if( arguments.type == "time" )
					var cellFormat = this.getDateFormats().TIME; //don't include the epoch date in the display
				else
					var cellFormat = getDefaultDateMaskFor( dateTimeValue );// check if DATE, TIME or TIMESTAMP
				var dataFormat = arguments.workbook.getCreationHelper().createDataFormat();
				//Use setCellStyleProperty() which will try to re-use an existing style rather than create a new one for every cell which may breach the 4009 styles per wookbook limit
				getCellUtil().setCellStyleProperty( arguments.cell, getCellUtil().DATA_FORMAT, dataFormat.getFormat( JavaCast( "string", cellFormat ) ) );
				/*  Excel uses a different epoch than CF (1900-01-01 versus 1899-12-30). "Time" only values will not display properly without special handling */
				if( arguments.type == "time" || isTimeOnlyValue( dateTimeValue ) ){
					dateTimeValue = dateTimeValue.Add( "d", 2 );//shift the epoch forward to match Excel's
					var javaDate = dateTimeValue.from( dateTimeValue.toInstant() );// dateUtil needs a java date
					dateTimeValue = ( getDateUtil().getExcelDate( javaDate ) -1 );//Convert to Excel's double value for dates, minus the 1 complete day to leave the day fraction (= time value)
				}
				arguments.cell.setCellValue( dateTimeValue );
				return;
			case "boolean":
				//handle empty strings/nulls which can't be treated as booleans
				if( Trim( arguments.value ).IsEmpty() ){
					arguments.cell.setBlank(); //no need to set the value: it will be blank
					return;
				}
				arguments.cell.setCellValue( JavaCast( "boolean", arguments.value ) );
				return;
			case "blank":
				arguments.cell.setBlank(); //no need to set the value: it will be blank
				return;
		}
		arguments.cell.setCellValue( JavaCast( "string", arguments.value ) );
	}

	private void function shiftCell( required workbook, required row, required numeric cellIndex, required numeric offset ){
		var originalCell = arguments.row.getCell( JavaCast( "int", arguments.cellIndex ) );
		if( IsNull( originalCell ) )
			return;
		var cell = createCell( arguments.row, arguments.cellIndex + arguments.offset );
		setCellValueAsType( arguments.workbook, cell, getCellValueAsType( arguments.workbook, originalCell ) );
		cell.setCellStyle( originalCell.getCellStyle() );
		cell.setCellComment( originalCell.getCellComment() );
		cell.setHyperlink( originalCell.getHyperLink() );
		arguments.row.removeCell( originalCell );
	}

	/* Query data */
	private query function deleteHiddenColumnsFromQuery( required sheet, required query result ){
		var startIndex = ( arguments.sheet.totalColumnCount -1 );
		for( var colIndex = startIndex; colIndex >= 0; colIndex-- ){
			if( !arguments.sheet.object.isColumnHidden( JavaCast( "int", colIndex ) ) )
				continue;
			var columnNumber = ( colIndex +1 );
			arguments.result = _QueryDeleteColumn( arguments.result, arguments.sheet.columnNames[ columnNumber ] );
			arguments.sheet.totalColumnCount--;
			arguments.sheet.columnNames.DeleteAt( columnNumber );
		}
		return arguments.result;
	}

	private string function detectQueryColumnTypesFromData( required array data, required numeric columnCount ){
		var types = [];
		cfloop( from=1, to=arguments.columnCount, index="local.colNum" ){
			types[ colNum ] = "";
			for( var row in arguments.data ){
				if( row.IsEmpty() || ( row.Len() < colNum ) )
					continue;//next column (ACF: empty values are sometimes just missing from the array??)
				var value = row[ colNum ];
				var detectedType = detectValueDataType( value );
				if( detectedType == "blank" )
					continue;//next column
				var mappedType = mapDataTypeToQueryColumnType( detectedType );
				if( types[ colNum ].Len() && mappedType != types[ colNum ] ){
					//mixed types
					types[ colNum ] = "VARCHAR";
					break;//stop processing row
				}
				types[ colNum ] = mappedType;
			}
			if( types[ colNum ].IsEmpty() )
				types[ colNum ] = "VARCHAR";
		}
		return types.ToList();
	}

	private string function mapDataTypeToQueryColumnType( required string dataType ){
		switch( arguments.dataType ){
			case "numeric": return "DOUBLE";
			case "date": return "TIMESTAMP";
			default: return "VARCHAR";
		}
	}

	private string function getQueryColumnTypesListFromStruct( required struct types, required array sheetColumnNames ){
		var result = [];
		for( var columnName IN arguments.sheetColumnNames ){
			result.Append( arguments.types.KeyExists( columnName )? arguments.types[ columnName ]: "VARCHAR" );
		}
		return result.ToList();
	}

	private array function getQueryColumnTypeToCellTypeMappings( required query query ){
		// extract the query columns and data types
		var metadata = GetMetaData( arguments.query );
		// assign default formats based on the data type of each column
		for( var columnMetadata in metadata )
			mapQueryColumnTypeToCellType( columnMetadata );
		return metadata;
	}

	private void function mapQueryColumnTypeToCellType( required struct columnMetadata ){
		var columnType = arguments.columnMetadata.typeName?: "";// typename is missing in ACF if not specified in the query
		switch( columnType ){
			case "DATE": case "TIMESTAMP": case "DATETIME": case "DATETIME2":
				arguments.columnMetadata.cellDataType = "DATE";
			return;
			case "TIME":
				arguments.columnMetadata.cellDataType = "TIME";
			return;
			/* Note: Excel only supports "double" for numbers. Casting very large DECIMIAL/NUMERIC or BIGINT values to double may result in a loss of precision or conversion to NEGATIVE_INFINITY / POSITIVE_INFINITY. */
			case "DECIMAL": case "BIGINT": case "NUMERIC": case "DOUBLE": case "FLOAT": case "INT": case "INTEGER": case "REAL": case "SMALLINT": case "TINYINT":
				arguments.columnMetadata.cellDataType = "DOUBLE";
			return;
			case "BOOLEAN": case "BIT":
				arguments.columnMetadata.cellDataType = "BOOLEAN";
			return;
			default: arguments.columnMetadata.cellDataType = "STRING";
		}
	}

	private string function queryToHtml( required query query, numeric headerRow, boolean includeHeaderRow=false ){
		var result = newJavaStringBuilder();
		var columns = _QueryColumnArray( arguments.query );
		var generateHeaderRow = ( arguments.includeHeaderRow && arguments.KeyExists( "headerRow" ) && Val( arguments.headerRow ) );
		if( generateHeaderRow ){
			result.Append( "<thead>" );
			result.Append( generateHtmlRow( columns, true ) );
			result.Append( "</thead>" );
		}
		result.Append( "<tbody>" );
		for( var row in arguments.query ){
			var rowValues = [];
			for( var column in columns )
				rowValues.Append( row[ column ] );
			result.Append( generateHtmlRow( rowValues ) );
		}
		result.Append( "</tbody>" );
		return result.toString();
	}

	private string function generateHtmlRow( required array values, boolean isHeader=false ){
		var result = newJavaStringBuilder();
		result.Append( "<tr>" );
		var columnTag = arguments.isHeader? "th": "td";
		for( var value in arguments.values ){
			if( isDateObject( value ) || _IsDate( value ) )
				value = DateTimeFormat( value, this.getDateFormats().DATETIME );
			result.Append( "<#columnTag#>#value#</#columnTag#>" );
		}
		result.Append( "</tr>" );
		return result.toString();
	}

	private string function parseQueryColumnTypesArgument(
		required any queryColumnTypes
		,required array columnNames
		,required numeric columnCount
		,required array data
	){
		if( IsStruct( arguments.queryColumnTypes ) )
			return getQueryColumnTypesListFromStruct( arguments.queryColumnTypes, arguments.columnNames );
		if( arguments.queryColumnTypes == "auto" )
			return detectQueryColumnTypesFromData( arguments.data, arguments.columnCount );
		if( ListLen( arguments.queryColumnTypes ) == 1 ){
			//single type: use as default for all
			var columnType = arguments.queryColumnTypes;
			return RepeatString( "#columnType#,", arguments.columnCount-1 ) & columnType;
		}
		return arguments.queryColumnTypes;
	}

	private void function throwErrorIFinvalidQueryColumnTypesArgument( required queryColumnTypes ){
		if( IsStruct( arguments.queryColumnTypes ) && !arguments.KeyExists( "headerRow" ) && !arguments.KeyExists( "columnNames" ) )
			Throw( type=this.getExceptionType(), message="Invalid argument 'queryColumnTypes'.", detail="When specifying 'queryColumnTypes' as a struct you must also specify the 'headerRow' or provide 'columnNames'" );
	}

	/* Ranges */

	private array function extractRanges( required string rangeList ){
		/*
		A range is a comma-delimited list of ranges, and each value can be either a single number or a range of numbers with a hyphen. Ignores any white space.
		Parses and validates a list of row/column numbers. Returns an array of structures with the keys: startAt, endAt
		*/
		var result = [];
		var rangeTest = "^[0-9]{1,}(-[0-9]{1,})?$";
		var ranges = ListToArray( arguments.rangeList );
		for( var thisRange in ranges ){
			thisRange = removeAllWhiteSpaceFrom( thisRange );
			if( !REFind( rangeTest, thisRange ) )
				Throw( type=this.getExceptionType(), message="Invalid range value", detail="The range value '#thisRange#' is not valid." );
			var parts = ListToArray( thisRange, "-" );
			//if this is a single number, the start/endAt values are the same
			var range = {
				startAt: parts[ 1 ]
				,endAt: parts[ parts.Len() ]
			};
			result.Append( range );
		}
		return result;
	}

	/* Value data types */

	private string function detectValueDataType( required value ){
		// Numeric must precede date test
		// Golden default rule: treat numbers with leading zeros as STRINGS: not numbers (lucee) or dates (ACF);
		// Do not detect booleans: leave as strings
		if( REFind( "^0[\d]+", arguments.value ) )
			return "string";
		if( IsNumeric( arguments.value ) )
			return "numeric";
		if( _IsDate( arguments.value ) )
			return "date";
		if( Trim( arguments.value ).IsEmpty() )
			return "blank";
		return "string";
	}

	private string function getCellValueTypeFromQueryColumnType( required string type, required cellValue ){
		switch( arguments.type ){
			case "DOUBLE":
				return "numeric";
			case "DATE": case "TIME": case "BOOLEAN":
				return arguments.type.LCase();
		}
		if( IsSimpleValue( arguments.cellValue ) && !Len( arguments.cellValue ) )//NB don't use member function: won't work if numeric
			return "blank";
		return "string";
	}

	private boolean function isString( required input ){
		return IsInstanceOf( arguments.input, "java.lang.String" );
	}

	/* Data type overriding */

	private void function checkDataTypesArgument( required struct args ){
		if( arguments.args.KeyExists( "datatypes" ) && datatypeOverridesContainInvalidTypes( arguments.args.datatypes ) )
			Throw( type=this.getExceptionType(), message="Invalid datatype(s)", detail="One or more of the datatypes specified is invalid. Valid types are #validCellOverrideTypes().ToList( ', ' )# and the columns they apply to should be passed as an array" );
	}

	private void function convertDataTypeOverrideColumnNamesToNumbers( required struct datatypeOverrides, required array columnNames ){
		for( var type in arguments.datatypeOverrides ){
			var columnRefs = arguments.datatypeOverrides[ type ];
			//NB: DO NOT SCOPE datatypeOverrides and columnNames vars inside closure!!
			columnRefs.Each( function( value, index ){
				if( !IsNumeric( value ) ){
					var columnNumber = ArrayFindNoCase( columnNames, value );//ACF won't accept member function on this array for some reason
					columnRefs.DeleteAt( index );
					columnRefs.Append( columnNumber );
					datatypeOverrides[ type ] = columnRefs;
				}
			});
		}
	}

	private boolean function datatypeOverridesContainInvalidTypes( required struct datatypeOverrides ){
		for( var type in arguments.datatypeOverrides ){
			if( !isValidCellOverrideType( type ) || !IsArray( arguments.datatypeOverrides[ type ] ) )
				return true;
		}
		return false;
	}

	private string function getCellTypeOverride( required numeric cellIndex, required struct datatypeOverrides ){
		var columnNumber = ( arguments.cellIndex +1 );
		for( var type in arguments.datatypeOverrides ){
			if( arguments.datatypeOverrides[ type ].Find( columnNumber ) )
				return type;
		}
		return "";
	}

	private boolean function isValidCellOverrideType( required string type ){
		return validCellOverrideTypes().FindNoCase( arguments.type );
	}

	private void function setCellDataTypeWithOverride(
		required workbook
		,required cell
		,required cellValue
		,required numeric cellIndex
		,required struct datatypeOverrides
		,string defaultType
	){
		var cellTypeOverride = getCellTypeOverride( arguments.cellIndex, arguments.datatypeOverrides );
		if( cellTypeOverride.Len() ){
			if( cellTypeOverride == "auto" ){
				setCellValueAsType( arguments.workbook, arguments.cell, arguments.cellValue );
				return;
			}
			if( valueCanBeSetAsType( arguments.cellValue, cellTypeOverride ) ){
				setCellValueAsType( arguments.workbook, arguments.cell, arguments.cellValue, cellTypeOverride );
				return;
			}
		}
		// if no override, use an already set default (i.e. query column type)
		if( arguments.KeyExists( "defaultType" ) ){
			setCellValueAsType( arguments.workbook, arguments.cell, arguments.cellValue, arguments.defaultType );
			return;
		}
		// default autodetect
		setCellValueAsType( arguments.workbook, arguments.cell, arguments.cellValue );
	}

	private array function validCellOverrideTypes(){
		return [ "numeric", "string", "date", "time", "boolean", "auto" ];
	}

	private boolean function valueCanBeSetAsType( required value, required type ){
		//when overriding types, check values can be cast as numbers or dates
		switch( arguments.type ){
			case "numeric":
				return IsNumeric( arguments.value );
			case "date": case "time":
				return _IsDate( arguments.value );
			case "boolean":
				return IsBoolean( arguments.value );
		}
		return true;
	}

	/* Dates */

	private string function getDefaultDateMaskFor( required date value ){
		var dateOnly = CreateDate( Year( arguments.value ), Month( arguments.value ), Day( arguments.value ) );
		if( isDateOnlyValue( arguments.value ) )
			return this.getDateFormats().DATE;
		if( isTimeOnlyValue( arguments.value ) )
			return this.getDateFormats().TIME;
		return this.getDateFormats().TIMESTAMP;
	}

	private boolean function isDateObject( required input ){
		return IsInstanceOf( arguments.input, "java.util.Date" );
	}

	private boolean function isDateOnlyValue( required date value ){
		var dateOnly = CreateDate( Year( arguments.value ), Month( arguments.value ), Day( arguments.value ) );
		return ( DateCompare( arguments.value, dateOnly, "s" ) == 0 );
	}

	private boolean function isTimeOnlyValue( required date value ){
		//NB: this will only detect CF time object (epoch = 1899-12-30), not those using unix epoch 1970-01-01
		return ( Year( arguments.value ) == "1899" );
	}

	/* CSV/Delimiters */

	private boolean function delimiterIsTab( required string delimiter ){
		return ArrayFindNoCase( [ "#Chr( 9 )#", "\t", "tab" ], arguments.delimiter );//CF2016 doesn't support [].FindNoCase( needle )
	}

	private any function getCsvFormatForDelimiter( required string delimiter ){
		if( delimiterIsTab( arguments.delimiter ) )
			return loadClass( "org.apache.commons.csv.CSVFormat" )[ JavaCast( "string", "TDF" ) ];
		return loadClass( "org.apache.commons.csv.CSVFormat" )[ JavaCast( "string", "RFC4180" ) ]
			.withDelimiter( JavaCast( "char", arguments.delimiter ) )
			.withIgnoreSurroundingSpaces();//stop spaces between fields causing problems with embedded lines
	}

	/* Info */

	private void function addInfoBinary( required workbook, required struct info ){
		arguments.workbook.createInformationProperties(); // creates the following if missing
		var documentSummaryInfo = arguments.workbook.getDocumentSummaryInformation();
		var summaryInfo = arguments.workbook.getSummaryInformation();
		for( var key in arguments.info )
			addInfoItemBinary( arguments.info, key, summaryInfo, documentSummaryInfo );
	}

	private void function addInfoItemBinary(
		required struct info
		,required string key
		,required summaryInfo
		,required documentSummaryInfo
	){
		var value = JavaCast( "string", arguments.info[ arguments.key ] );
		switch( arguments.key ){
			case "author": arguments.summaryInfo.setAuthor( value );
				return;
			case "category": arguments.documentSummaryInfo.setCategory( value );
				return;
			case "lastauthor": arguments.summaryInfo.setLastAuthor( value );
				return;
			case "comments": arguments.summaryInfo.setComments( value );
				return;
			case "keywords": arguments.summaryInfo.setKeywords( value );
				return;
			case "manager": arguments.documentSummaryInfo.setManager( value );
				return;
			case "company": arguments.documentSummaryInfo.setCompany( value );
				return;
			case "subject": arguments.summaryInfo.setSubject( value );
				return;
			case "title": arguments.summaryInfo.setTitle( value );
		}
	}

	private void function addInfoXml( required workbook, required struct info ){
		var workbookProperties = isStreamingXmlFormat( arguments.workbook )? arguments.workbook.getXSSFWorkbook().getProperties(): arguments.workbook.getProperties();
		var documentProperties = workbookProperties.getExtendedProperties().getUnderlyingProperties();
		var coreProperties = workbookProperties.getCoreProperties();
		for( var key in arguments.info )
			addInfoItemXml( arguments.info, key, documentProperties, coreProperties );
	}

	private void function addInfoItemXml(
		required struct info
		,required string key
		,required documentProperties
		,required coreProperties
	){
		var value = JavaCast( "string", arguments.info[ key ] );
		switch( arguments.key ){
			case "author": arguments.coreProperties.setCreator( value  );
				return;
			case "category": arguments.coreProperties.setCategory( value );
				return;
			case "lastauthor": arguments.coreProperties.getUnderlyingProperties().setLastModifiedByProperty( value );
				return;
			case "comments": arguments.coreProperties.setDescription( value );
				return;
			case "keywords": arguments.coreProperties.setKeywords( value );
				return;
			case "subject": arguments.coreProperties.setSubjectProperty( value );
				return;
			case "title": arguments.coreProperties.setTitle( value );
				return;
			case "manager": arguments.documentProperties.setManager( value );
				return;
			case "company": arguments.documentProperties.setCompany( value );
		}
	}
	
	private struct function binaryInfo( required workbook ){
		var documentProperties = arguments.workbook.getDocumentSummaryInformation();
		var coreProperties = arguments.workbook.getSummaryInformation();
		return {
			author: coreProperties.getAuthor()?:""
			,category: documentProperties.getCategory()?:""
			,comments: coreProperties.getComments()?:""
			,creationDate: coreProperties.getCreateDateTime()?:""
			,lastEdited: ( coreProperties.getEditTime() == 0 )? "": CreateObject( "java", "java.util.Date" ).init( coreProperties.getEditTime() )
			,subject: coreProperties.getSubject()?:""
			,title: coreProperties.getTitle()?:""
			,lastAuthor: coreProperties.getLastAuthor()?:""
			,keywords: coreProperties.getKeywords()?:""
			,lastSaved: coreProperties.getLastSaveDateTime()?:""
			,manager: documentProperties.getManager()?:""
			,company: documentProperties.getCompany()?:""
		};
	}

	private struct function xmlInfo( required workbook ){
		var workbookProperties = isStreamingXmlFormat( arguments.workbook )? arguments.workbook.getXSSFWorkbook().getProperties(): arguments.workbook.getProperties();
		var documentProperties = workbookProperties.getExtendedProperties().getUnderlyingProperties();
		var coreProperties = workbookProperties.getCoreProperties();
		var result = {
			author: coreProperties.getCreator()?:""
			,category: coreProperties.getCategory()?:""
			,comments: coreProperties.getDescription()?:""
			,creationDate: coreProperties.getCreated()?:""
			,lastEdited: coreProperties.getModified()?:""
			,subject: coreProperties.getSubject()?:""
			,title: coreProperties.getTitle()?:""
			,keywords: coreProperties.getKeywords()?:""
			,lastSaved: ""// not available in xml
			,manager: documentProperties.getManager()?:""
			,company: documentProperties.getCompany()?:""
		};
		// lastAuthor is a java.util.Option object with different behaviour
		if( coreProperties.getUnderlyingProperties().getLastModifiedByProperty().isPresent() )
			result.lastAuthor = coreProperties.getUnderlyingProperties().getLastModifiedByProperty().get();
		return result;
	}

	/* Visibility */

	private void function doFillMergedCellsWithVisibleValue( required workbook, required sheet ){
		if( !sheetHasMergedRegions( arguments.sheet ) )
			return;
		for( var regionIndex = 0; regionIndex < arguments.sheet.getNumMergedRegions(); regionIndex++ ){
			var region = arguments.sheet.getMergedRegion( regionIndex );
			var regionStartRowNumber = ( region.getFirstRow() +1 );
			var regionEndRowNumber = ( region.getLastRow() +1 );
			var regionStartColumnNumber = ( region.getFirstColumn() +1 );
			var regionEndColumnNumber = ( region.getLastColumn() +1 );
			var visibleValue = getCellValue( arguments.workbook, regionStartRowNumber, regionStartColumnNumber );
			setCellRangeValue( arguments.workbook, visibleValue, regionStartRowNumber, regionEndRowNumber, regionStartColumnNumber, regionEndColumnNumber );
		}
	}

	private void function toggleColumnHidden( required workbook, required numeric columnNumber, required boolean state ){
		getActiveSheet( arguments.workbook ).setColumnHidden( JavaCast( "int", arguments.columnNumber-1 ), JavaCast( "boolean", arguments.state ) );
	}

	private void function toggleRowHidden( required workbook, required numeric rowNumber, required boolean state ){
		getRowFromActiveSheet( arguments.workbook, arguments.rowNumber ).setZeroHeight( JavaCast( "boolean", arguments.state ) );
	}

	/* Formatting */

	private any function buildCellStyle( required workbook, required struct format, existingStyle ){
		var cellStyle = arguments.workbook.createCellStyle();
		if( arguments.KeyExists( "existingStyle" ) )
			cellStyle.cloneStyleFrom( arguments.existingStyle );
		for( var setting in arguments.format )
			setCellStyleFromFormatSetting( arguments.workbook, cellStyle, arguments.format, setting );
		return cellStyle;
	}

	private void function setCellStyleFromFormatSetting(
		required workbook
		,required cellStyle
		,required struct format
		,required string setting
	){
		var font = 0;
		var settingValue = arguments.format[ setting ];
		switch( arguments.setting ){
			case "alignment":
				var alignment = arguments.cellStyle.getAlignment()[ JavaCast( "string", UCase( settingValue ) ) ];
				arguments.cellStyle.setAlignment( alignment );
			return;
			case "bold":
				font = cloneFont( arguments.workbook, arguments.workbook.getFontAt( arguments.cellStyle.getFontIndexAsInt() ) );
				font.setBold( JavaCast( "boolean", settingValue ) );
				arguments.cellStyle.setFont( font );
			return;
			case "bottomborder":
				var borderStyle = arguments.cellStyle.getBorderBottom()[ JavaCast( "string", UCase( settingValue ) ) ];
				arguments.cellStyle.setBorderBottom( borderStyle );
			return;
			case "bottombordercolor":
				arguments.cellStyle.setBottomBorderColor( getColor( arguments.workbook, settingValue ) );
			return;
			case "color":
				font = cloneFont( arguments.workbook, arguments.workbook.getFontAt( arguments.cellStyle.getFontIndexAsInt() ) );
				font.setColor( getColor( arguments.workbook, settingValue ) );
				arguments.cellStyle.setFont( font );
			return;
			case "dataformat":
				var dataFormat = arguments.workbook.getCreationHelper().createDataFormat();
				arguments.cellStyle.setDataFormat( dataFormat.getFormat( JavaCast( "string", settingValue ) ) );
			return;
			case "fgcolor":
				arguments.cellStyle.setFillForegroundColor( getColor( arguments.workbook, settingValue ) );
				// make sure we always apply a fill pattern or the color will not be visible
				if( !arguments.format.KeyExists( "fillpattern" ) ){
					var fillpattern = arguments.cellStyle.getFillPattern()[ JavaCast( "string", "SOLID_FOREGROUND" ) ];
					arguments.cellStyle.setFillPattern( fillpattern );
				}
			return;
			case "fillpattern":
			 //ACF docs list "nofill" as opposed to "no_fill"
				if( settingValue == "nofill" )
					settingValue = "NO_FILL";
				var fillpattern = arguments.cellStyle.getFillPattern()[ JavaCast( "string", UCase( settingValue ) ) ];
				arguments.cellStyle.setFillPattern( fillpattern );
			return;
			case "font":
				font = cloneFont( arguments.workbook, arguments.workbook.getFontAt( arguments.cellStyle.getFontIndexAsInt() ) );
				font.setFontName( JavaCast( "string", settingValue ) );
				arguments.cellStyle.setFont( font );
			return;
			case "fontsize":
				font = cloneFont( arguments.workbook, arguments.workbook.getFontAt( arguments.cellStyle.getFontIndexAsInt() ) );
				font.setFontHeightInPoints( JavaCast( "int", settingValue ) );
				arguments.cellStyle.setFont( font );
			return;
			//  TODO: Doesn't seem to do anything/
			case "hidden":
				arguments.cellStyle.setHidden( JavaCast( "boolean", settingValue ) );
			return;
			case "indent":
				// Only seems to work on MS Excel. XLS limit is 15.
				var indentValue = isXmlFormat( arguments.workbook )? settingValue: Min( 15, settingValue );
				arguments.cellStyle.setIndention( JavaCast( "int", indentValue ) );
			return;
			case "italic":
				font = cloneFont( arguments.workbook, arguments.workbook.getFontAt( arguments.cellStyle.getFontIndexAsInt ( ) ) );
				font.setItalic( JavaCast( "boolean", settingValue ) );
				arguments.cellStyle.setFont( font );
			return;
			case "leftborder":
				var borderStyle = arguments.cellStyle.getBorderLeft()[ JavaCast( "string", UCase( settingValue ) ) ];
				arguments.cellStyle.setBorderLeft( borderStyle );
			return;
			case "leftbordercolor":
				arguments.cellStyle.setLeftBorderColor( getColor( arguments.workbook, settingValue ) );
			return;
			// TODO: Doesn't seem to do anything
			case "locked":
				arguments.cellStyle.setLocked( JavaCast( "boolean", settingValue ) );
			return;
			case "quoteprefixed":
				arguments.cellStyle.setQuotePrefixed( JavaCast( "boolean", settingValue ) );
			return;
			case "rightborder":
				var borderStyle = arguments.cellStyle.getBorderRight()[ JavaCast( "string", UCase( settingValue ) ) ];
				arguments.cellStyle.setBorderRight( borderStyle );
			return;
			case "rightbordercolor":
				arguments.cellStyle.setRightBorderColor( getColor( arguments.workbook, settingValue ) );
			return;
			case "rotation":
				arguments.cellStyle.setRotation( JavaCast( "int", settingValue ) );
			return;
			case "strikeout":
				font = cloneFont( arguments.workbook, arguments.workbook.getFontAt( arguments.cellStyle.getFontIndexAsInt() ) );
				font.setStrikeout( JavaCast( "boolean", settingValue ) );
				arguments.cellStyle.setFont( font );
			return;
			case "textwrap":
				arguments.cellStyle.setWrapText( JavaCast( "boolean", settingValue ) );
			return;
			case "topborder":
				var borderStyle = arguments.cellStyle.getBorderTop()[ JavaCast( "string", UCase( settingValue ) ) ];
				arguments.cellStyle.setBorderTop( borderStyle );
			return;
			case "topbordercolor":
				arguments.cellStyle.setTopBorderColor( getColor( arguments.workbook, settingValue ) );
			return;
			case "underline":
				var underlineType = lookupUnderlineFormat( settingValue );
				if( underlineType == -1 )
					return;
				font = cloneFont( arguments.workbook, arguments.workbook.getFontAt( arguments.cellStyle.getFontIndexAsInt() ) );
				font.setUnderline( JavaCast( "byte", underlineType ) );
				arguments.cellStyle.setFont( font );
			return;
			case "verticalalignment":
				var alignment = arguments.cellStyle.getVerticalAlignment()[ JavaCast( "string", UCase( settingValue ) ) ];
				arguments.cellStyle.setVerticalAlignment( alignment );
		}
	}

	private boolean function isValidCellStyleObject( required workbook, required any object ){
		if( isBinaryFormat( arguments.workbook ) )
			return ( arguments.object.getClass().getCanonicalName() == "org.apache.poi.hssf.usermodel.HSSFCellStyle" );
		return ( arguments.object.getClass().getCanonicalName() == "org.apache.poi.xssf.usermodel.XSSFCellStyle" );
	}

	private void function checkFormatArguments( required workbook, boolean overwriteCurrentStyle=true ){
		if( arguments.KeyExists( "cellStyle" ) && !arguments.overwriteCurrentStyle )
			Throw( type=this.getExceptionType(), message="Invalid arguments", detail="If you supply a 'cellStyle' the 'overwriteCurrentStyle' cannot be false" );
		if( arguments.KeyExists( "cellStyle" ) && !isValidCellStyleObject( arguments.workbook, arguments.cellStyle ) )
			Throw( type=this.getExceptionType(), message="Invalid argument", detail="The 'cellStyle' argument is not a valid POI cellStyle object" );
	}

	private void function addCellStyleToFormatMethodArgsIfStyleOverwriteAllowed( required workbook, required boolean overwriteCurrentStyle, required struct formatMethodArgs, required struct format ){
		if( arguments.overwriteCurrentStyle )
			arguments.formatMethodArgs.cellStyle = arguments.cellStyle?: buildCellStyle( arguments.workbook, arguments.format );
	}

	private string function lookupUnderlineFormatCode( required cellFont ){
		switch( arguments.cellFont.getUnderline() ){
			case 0: return "none";
			case 1: return "single";
			case 2: return "double";
			case 33: return "single accounting";
			case 34: return "double accounting";
			default: return "unknown";
		}
	}

	private numeric function lookupUnderlineFormat( required any formatSettingValue ){
		switch( arguments.formatSettingValue ){
			case "none": return 0;
			case "single": return 1;
			case "double": return 2;
			case "single accounting": return 33;
			case "double accounting": return 34;
		}
		if( IsBoolean( arguments.formatSettingValue ) )
			return arguments.formatSettingValue? 1: 0;
		return -1;
	}

	private string function richStringCellValueToHtml( required workbook, required cell, required cellValue ){
		var richTextValue = arguments.cell.getRichStringCellValue();
		var totalRuns = richTextValue.numFormattingRuns();
		var baseFont = arguments.cell.getCellStyle().getFont( arguments.workbook );
		if( totalRuns == 0  )
			return baseFontToHtml( arguments.workbook, arguments.cellValue, baseFont );
		// Runs never start at the beginning: the string before the first run is always in the baseFont format
		var startOfFirstRun = richTextValue.getIndexOfFormattingRun( 0 );
		var initialContents = arguments.cellValue.Mid( 1, startOfFirstRun );//before the first run
		var initialHtml = baseFontToHtml( arguments.workbook, initialContents, baseFont );
		var result = newJavaStringBuilder();
		result.Append( initialHtml );
		var endOfCellValuePosition = arguments.cellValue.Len();
		for( var runIndex = 0; runIndex < totalRuns; runIndex++ ){
			var run = {};
			run.index = runIndex;
			run.number = ( runIndex +1 );
			run.font = arguments.workbook.getFontAt( richTextValue.getFontOfFormattingRun( runIndex ) );
			run.css = runFontToHtml( arguments.workbook, baseFont, run.font );
			run.isLast = ( run.number == totalRuns );
			run.startPosition = ( richTextValue.getIndexOfFormattingRun( runIndex ) +1 );
			run.endPosition = run.isLast? endOfCellValuePosition: richTextValue.getIndexOfFormattingRun( ( runIndex +1 ) );
			run.length = ( ( run.endPosition +1 ) -run.startPosition );
			run.content = arguments.cellValue.Mid( run.startPosition, run.length );
			if( run.css.IsEmpty() ){
				result.Append( run.content );
				continue;
			}
			run.html = '<span style="#run.css#">#run.content#</span>';
			result.Append( run.html );
		}
		return result.toString();
	}

	/* Fonts */

	private string function baseFontToHtml( required workbook, required contents, required baseFont ){
		/*
			the order of processing is important for the tests to match
			font family and size not parsed here because all cells would trigger formatting of these attributes: defaults can't be assumed
		*/
		var cssStyles = newJavaStringBuilder();
		// bold
		if( arguments.baseFont.getBold() )
			cssStyles.Append( fontStyleToCss( "bold", true ) );
		// color
		if( !fontColorIsBlack( arguments.baseFont.getColor() ) )
			cssStyles.Append( fontStyleToCss( "color", arguments.baseFont.getColor(), arguments.workbook ) );
		// italic
		if( arguments.baseFont.getItalic() )
			cssStyles.Append( fontStyleToCss( "italic", true ) );
		// underline/strike
		if( arguments.baseFont.getStrikeout() || arguments.baseFont.getUnderline() ){
			var decorationValue	=	[];
			if( arguments.baseFont.getStrikeout() )
				decorationValue.Append( "line-through" );
			if( arguments.baseFont.getUnderline() )
				decorationValue.Append( "underline" );
			cssStyles.Append( fontStyleToCss( "decoration", decorationValue.ToList( " " ) ) );
		}
		cssStyles = cssStyles.toString();
		if( cssStyles.IsEmpty() )
			return arguments.contents;
		return "<span style=""#cssStyles#"">#arguments.contents#</span>";
	}

	private any function cloneFont( required workbook, required fontToClone ){
		var newFont = arguments.workbook.createFont();
		// copy the existing cell's font settings to the new font
		newFont.setBold( arguments.fontToClone.getBold() );
		newFont.setCharSet( arguments.fontToClone.getCharSet() );
		// xlsx fonts contain XSSFColor objects which may have been set as RGB
		var color = isXmlFormat( arguments.workbook )? arguments.fontToClone.getXSSFColor(): arguments.fontToClone.getColor();
		// reportedly getXSSFColor() returns null in some conditions (not reproducible)
		if( !IsNull( color ) )
			newFont.setColor( color );
		newFont.setFontHeight( arguments.fontToClone.getFontHeight() );
		newFont.setFontName( arguments.fontToClone.getFontName() );
		newFont.setItalic( arguments.fontToClone.getItalic() );
		newFont.setStrikeout( arguments.fontToClone.getStrikeout() );
		newFont.setTypeOffset( arguments.fontToClone.getTypeOffset() );
		newFont.setUnderline( arguments.fontToClone.getUnderline() );
		return newFont;
	}

	private boolean function fontColorIsBlack( required fontColor ){
		return ( arguments.fontColor == 8 ) || ( arguments.fontColor == 32767 );
	}

	private string function fontStyleToCss( required string styleType, required any styleValue, workbook ){
		/*
		Support limited to:
			bold
			color
			italic
			strikethrough
			single underline
		*/
		switch( arguments.styleType ){
			case "bold":
				return "font-weight:" & ( arguments.styleValue? "bold;": "normal;" );
			case "color":
				if( !arguments.KeyExists( "workbook" ) )
					Throw( type=this.getExceptionType(), message="The 'workbook' argument is required when generating color css styles" );
				//http://ragnarock99.blogspot.co.uk/2012/04/getting-hex-color-from-excel-cell.html
				var rgb = arguments.workbook.getCustomPalette().getColor( arguments.styleValue ).getTriplet();
				var javaColor = CreateObject( "Java", "java.awt.Color" ).init( JavaCast( "int", rgb[ 1 ] ), JavaCast( "int", rgb[ 2 ] ), JavaCast( "int", rgb[ 3 ] ) );
				var hex	=	CreateObject( "Java", "java.lang.Integer" ).toHexString( javaColor.getRGB() );
				hex = hex.subString( 2, hex.length() );
				return "color:##" & hex & ";";
			case "italic":
				return "font-style:" & ( arguments.styleValue? "italic;": "normal;" );
			case "decoration":
				return "text-decoration:#arguments.styleValue#;";//need to pass desired combination of "underline" and "line-through"
		}
		Throw( type=this.getExceptionType(), message="Unrecognised style for css conversion" );
	}

	private numeric function getAWTFontStyle( required any poiFont ){
		var font = loadClass( "java.awt.Font" );
		var isBold = arguments.poiFont.getBold();
		if( isBold && arguments.poiFont.getItalic() )
			return BitOr( font.BOLD, font.ITALIC );
		if( isBold )
			return font.BOLD;
		if( arguments.poiFont.getItalic() )
			return font.ITALIC;
		return font.PLAIN;
	}

	private numeric function getDefaultCharWidth( required workbook ){
		/*
			Estimates the default character width using Excel's 'Normal' font
			this is a compromise between hard coding a default value and the more complex method of using an AttributedString and TextLayout
		*/
		var defaultFont = arguments.workbook.getFontAt( 0 );
		var style = getAWTFontStyle( defaultFont );
		var font = loadClass( "java.awt.Font" );
		var javaFont = font.init( defaultFont.getFontName(), style, defaultFont.getFontHeightInPoints() );
		var transform = CreateObject( "java", "java.awt.geom.AffineTransform" );
		var fontContext = CreateObject( "java", "java.awt.font.FontRenderContext" ).init( transform, true, true );
		var bounds = javaFont.getStringBounds( "0", fontContext );
		return bounds.getWidth();
	}

	private string function runFontToHtml( required workbook, required baseFont, required runFont ){
		// NB: the order of processing is important for the tests to match
		var cssStyles = newJavaStringBuilder();
		// bold
		if( Compare( arguments.runFont.getBold(), arguments.baseFont.getBold() ) )
			cssStyles.Append( fontStyleToCss( "bold", arguments.runFont.getBold() ) );
		// color
		if( Compare( arguments.runFont.getColor(), arguments.baseFont.getColor() ) && !fontColorIsBlack( arguments.runFont.getColor() ) )
			cssStyles.Append( fontStyleToCss( "color", arguments.runFont.getColor(), arguments.workbook ) );
		// italic
		if( Compare( arguments.runFont.getItalic(), arguments.baseFont.getItalic() ) )
			cssStyles.Append( fontStyleToCss( "italic", arguments.runFont.getItalic() ) );
		// underline/strike
		if( Compare( arguments.runFont.getStrikeout(), arguments.baseFont.getStrikeout() ) || Compare( arguments.runFont.getUnderline(), arguments.baseFont.getUnderline() ) ){
			var decorationValue	=	[];
			if( !arguments.baseFont.getStrikeout() && arguments.runFont.getStrikeout() )
				decorationValue.Append( "line-through" );
			if( !arguments.baseFont.getUnderline() && arguments.runFont.getUnderline() )
				decorationValue.Append( "underline" );
			//if either or both are in the base format, and either or both are NOT in the run format, set the decoration to none.
			if(
					( arguments.baseFont.getUnderline() || arguments.baseFont.getStrikeout() )
					&&
					( !arguments.runFont.getUnderline() || !arguments.runFont.getUnderline() )
				){
				cssStyles.Append( fontStyleToCss( "decoration", "none" ) );
			}
			else
				cssStyles.Append( fontStyleToCss( "decoration", decorationValue.ToList( " " ) ) );
		}
		return cssStyles.toString();
	}
	
	/* Color */

	private array function convertSignedRGBToPositiveTriplet( required any signedRGB ){
		// When signed, values of 128+ are negative: convert then to positive values
		var result = [];
		for( var i=1; i <= 3; i++ ){
			result.Append( ( arguments.signedRGB[ i ] < 0 )? ( arguments.signedRGB[ i ] + 256 ): arguments.signedRGB[ i ] );
		}
		return result;
	}

	private numeric function getColorIndex( required string colorName ){
		var findColor = arguments.colorName.Trim().UCase();
		//check for 9 extra colours from old org.apache.poi.ss.usermodel.IndexedColors and map
		var deprecatedNames = [ "BLACK1", "WHITE1", "RED1", "BRIGHT_GREEN1", "BLUE1", "YELLOW1", "PINK1", "TURQUOISE1", "LIGHT_TURQUOISE1" ];
		if( ArrayFind( deprecatedNames, findColor ) )
			findColor = findColor.Left( findColor.Len() - 1 );
		var indexedColors = loadClass( "org.apache.poi.hssf.util.HSSFColor$HSSFColorPredefined" );
		try{
			var color = indexedColors.valueOf( JavaCast( "string", findColor ) );
			return color.getIndex();
		}
		catch( any exception ){
			Throw( type=this.getExceptionType(), message="Invalid Color", detail="The color provided (#arguments.colorName#) is not valid. Use getPresetColorNames() for a list of valid color names" );
		}
	}

	private boolean function isHexColor( required string inputString ){
		return arguments.inputString.REFind( "^##?[0-9A-Fa-f]{6,6}$" );
	}

	private string function hexToRGB( required string hexColor ){
		if( !isHexColor( arguments.hexColor ) )
			return "";
		arguments.hexColor = arguments.hexColor.Replace( "##", "" );
		var response = [];
		for( var i=1; i <= 5; i=i+2 ){
			response.Append( InputBaseN( Mid( arguments.hexColor, i, 2 ), 16 ) );
		}
		return response.ToList();
	}

	private any function getColor( required workbook, required string colorValue ){
		/*
			if colorValue is a preset name, returns the index
			if colorValue is hex it will be converted to RGB
			if colorValue is an RGB Triplet eg. "255,255,255" then the exact color object is returned for xlsx, or the nearest color's index if xls
		*/
		var isRGB = ListLen( arguments.colorValue ) == 3;
		if( !isRGB && !isHexColor( arguments.colorValue ) )
			return getColorIndex( arguments.colorValue );
		if( !isRGB && isHexColor( arguments.colorValue ) )
			arguments.colorValue = hexToRGB( arguments.colorValue );
		var rgb = ListToArray( arguments.colorValue );
		if( isXmlFormat( arguments.workbook ) ){
			var rgbBytes = [
				JavaCast( "int", rgb[ 1 ] )
				,JavaCast( "int", rgb[ 2 ] )
				,JavaCast( "int", rgb[ 3 ] )
			];
			try{
				return loadClass( "org.apache.poi.xssf.usermodel.XSSFColor" ).init( JavaCast( "byte[]", rgbBytes ), JavaCast( "null", 0 ) );
			}
			//ACF doesn't handle signed java byte values the same way as Lucee: see https://www.bennadel.com/blog/2689-creating-signed-java-byte-values-using-coldfusion-numbers.htm
			catch( any exception ){
				if( !exception.message CONTAINS "cannot fit inside a byte" )
					rethrow;
				//ACF2016+ Bitwise operators can't handle >32-bit args: https://stackoverflow.com/questions/43176313/cffunction-cfargument-pass-unsigned-int32
				var javaLangInteger = CreateObject( "java", "java.lang.Integer" );
				var negativeMask = InputBaseN( ( "11111111" & "11111111" & "11111111" & "00000000" ), 2 );
				negativeMask = javaLangInteger.parseUnsignedInt( negativeMask );
				rgbBytes = [];
				for( var value in rgb ){
					if( BitMaskRead( value, 7, 1 ) )
					value = BitOr( negativeMask, value );//value greater than 127
					rgbBytes.Append( JavaCast( "byte", value ) );
				}
				return loadClass( "org.apache.poi.xssf.usermodel.XSSFColor" ).init( JavaCast( "byte[]", rgbBytes ), JavaCast( "null", 0 ) );
			}
		}
		var palette = arguments.workbook.getCustomPalette();
		var similarExistingColor = palette.findSimilarColor(
			JavaCast( "int", rgb[ 1 ] )
			,JavaCast( "int", rgb[ 2 ] )
			,JavaCast( "int", rgb[ 3 ] )
		);
		return similarExistingColor.getIndex();
	}

	private struct function getJavaColorRGBFor( required string colorName ){
		var findColor = arguments.colorName.Trim().UCase();
		var color = CreateObject( "Java", "java.awt.Color" );
		if( IsNull( color[ findColor ] ) || !IsInstanceOf( color[ findColor ], "java.awt.Color" ) )//don't use member functions on color
			Throw( type=this.getExceptionType(), message="Invalid color", detail="The color provided (#arguments.colorName#) is not valid." );
		color = color[ findColor ];
		var colorRGB = {
			red: color.getRed()
			,green: color.getGreen()
			,blue: color.getBlue()
		};
		return colorRGB;
	}

	private string function getRgbTripletForStyleColorFormat( required workbook, required cellStyle, required string format ){
		var isXlsx = isXmlFormat( arguments.workbook );
		var palette = isXlsx? "": arguments.workbook.getCustomPalette();
		var colorObject = getColorObjectForFormat( arguments.format, arguments.cellStyle, palette, isXlsx );
		// HSSF will return an empty string rather than a null if the color doesn't exist
		if( IsNull( colorObject ) || IsSimpleValue( colorObject) )
			return "";
		var rgbTriplet = isXlsx? convertSignedRGBToPositiveTriplet( colorObject.getRGB() ): colorObject.getTriplet();
		return ArrayToList( rgbTriplet );
	}

	private any function getColorObjectForFormat(
		required string format
		,required cellStyle
		,required any palette
		,required boolean isXlsx
	){
		switch( arguments.format ){
			case "bottombordercolor":
				return arguments.isXlsx? arguments.cellStyle.getBottomBorderXSSFColor(): arguments.palette.getColor( arguments.cellStyle.getBottomBorderColor() );
			case "fgcolor":
				return arguments.isXlsx? arguments.cellStyle.getFillForegroundXSSFColor(): arguments.palette.getColor( arguments.cellStyle.getFillForegroundColor() );
			case "leftbordercolor":
				return arguments.isXlsx? arguments.cellStyle.getLeftBorderXSSFColor(): arguments.palette.getColor( arguments.cellStyle.getLeftBorderColor() );
			case "rightbordercolor":
				return arguments.isXlsx? arguments.cellStyle.getRightBorderXSSFColor(): arguments.palette.getColor( arguments.cellStyle.getRightBorderColor() );
			case "topbordercolor":
				return arguments.isXlsx? arguments.cellStyle.getTopBorderXSSFColor(): arguments.palette.getColor( arguments.cellStyle.getTopBorderColor() );
		}
	}

	/* Return helper objects */

	private any function getCellUtil(){
		if( IsNull( variables.cellUtil ) )
			variables.cellUtil = loadClass( "org.apache.poi.ss.util.CellUtil" );
		return variables.cellUtil;
	}

	private any function getDataFormatter(){
		if( IsNull( variables.dataFormatter ) )
			variables.dataFormatter = loadClass( "org.apache.poi.ss.usermodel.DataFormatter" ).init();
		return variables.dataFormatter;
	}

	private any function getDateUtil(){
		if( IsNull( variables.dateUtil ) )
			variables.dateUtil = loadClass( "org.apache.poi.ss.usermodel.DateUtil" );
		return variables.dateUtil;
	}

	private any function newJavaStringBuilder(){
		return CreateObject( "Java", "java.lang.StringBuilder" ).init();
	}

	/* Override troublesome engine BIFs */

	private boolean function _IsDate( required value ){
		if( !IsDate( arguments.value ) )
			return false;
		// Lucee will treat 01-23112 or 23112-01 as a date!
		if( ParseDateTime( arguments.value ).Year() > 9999 ) //ACF future limit
			return false;
		// ACF accepts "9a", "9p", "9 a" as dates
		// ACF no member function
		if( REFind( "^\d+\s*[apAP]{1,1}$", arguments.value ) )
			return false;
		return true;
	}

	/* ACF compatibility functions */
	private array function _QueryColumnArray( required query q ){
		try{
			return QueryColumnArray( arguments.q ); // Lucee
		}
		catch( any exception ){
			if( !exception.message CONTAINS "undefined" )
				rethrow;
			// ACF
			return q.getColumnNames();
		}
	}

	private query function _QueryDeleteColumn( required query q, required string columnToDelete ){
		try{
			QueryDeleteColumn( arguments.q, arguments.columnToDelete ); // Lucee/ACF2018+
			return arguments.q;
		}
		catch( any exception ){
			if( !exception.message CONTAINS "undefined" )
				rethrow;
			//ACF2016 doesn't support QueryDeleteColumn()
			var columnPosition = ListFindNoCase( arguments.q.columnList, arguments.columnToDelete );
			if( !columnPosition )
				return arguments.q;
			var columnsToKeep = ListDeleteAt( arguments.q.columnList, columnPosition );
			if( !columnsToKeep.Len() )
				return QueryNew( "" );
			return QueryExecute( "SELECT #columnsToKeep# FROM arguments.q", {}, { dbType = "query" } );
		}
	}

	private query function _QueryNew(
		required array columnNames
		,required string columnTypeList
		,required array data //NB: 'data' should not contain structs since they use the column name as key: always use array of row arrays instead
		,boolean makeColumnNamesSafe=false
	){
		if( arguments.makeColumnNamesSafe )
			arguments.columnNames = getSafeColumnNames( arguments.columnNames );
		if( !this.getIsACF() ) //Lucee
			return QueryNew( arguments.columnNames, arguments.columnTypeList, arguments.data );
		//ACF
 		if( arguments.makeColumnNamesSafe || !itemsContainAnInvalidVariableName( arguments.columnNames ) ) // Column names will be accepted and case preserved
			return QueryNew( arguments.columnNames.ToList(), arguments.columnTypeList, arguments.data ); //ACF requires a list, not an array.
		/*
			ACF QueryNew() won't accept invalid variable names in the column name list (e.g. names including commas or spaces, or starting with a number).
			The following workaround allows the original column names to be used
		*/
		// Create a query with safe column names
		var totalColumns = arguments.columnNames.Len();
		var safeColumnNames = [];
		for( var i=1; i <= totalColumns; i++ ){
			safeColumnNames[ i ] = "C#i#";
		}
		var query = QueryNew( safeColumnNames.ToList(), arguments.columnTypeList, arguments.data );
		// serialise the new query and column names to JSON strings, and restore the original column names using string replace
		var safeColumnNamesAsJson = SerializeJSON( safeColumnNames );
		var originalColumnNamesAsJson = SerializeJSON( arguments.columnNames );
		var queryAsJsonColumnsReplaced = SerializeJSON( query ).Replace( 'COLUMNS":' & safeColumnNamesAsJson, 'COLUMNS":' & originalColumnNamesAsJson );
		query = DeserializeJSON( queryAsJsonColumnsReplaced, false );
		if( arguments.columnTypeList.IsEmpty() )
			return query;
		// restore the column types which will have been lost in serialization. Method is ACF ONLY!
		query.getMetaData().setColumnTypeNames( arguments.columnTypeList.ListToArray() );
		return query;
	}

	/* General utilities */

	private array function getSafeColumnNames( required array columnNames ){
		var existingNames = {};
		return arguments.columnNames.Map( function( name ){
			name = makeVariableNameSafe( name );
			return makeDuplicateNameUnique( name, existingNames );
		});
	}

	private boolean function itemsContainAnInvalidVariableName( required array items ){
		for( var item IN arguments.items ){
			if( !IsValid( "variableName", item ) )
				return true;
		}
		return false;
	}

	private string function makeDuplicateNameUnique( required string name, required struct existingNames ){
		if( arguments.existingNames.KeyExists( arguments.name ) ){
			arguments.existingNames[ arguments.name ]++;
			return arguments.name & arguments.existingNames[ arguments.name ];
		}
		arguments.existingNames[ arguments.name ] = 1;
		return arguments.name;
	}

	private string function makeVariableNameSafe( required string variableName ){
		//NOTE: Lucee doesn't allow currency symbols (unlike ACF)
		if( IsValid( "variableName", arguments.variableName ) )
			return arguments.variableName;
		return JavaCast( "string", arguments.variableName )
			.Trim()
			.ReplaceFirst( "^\d", "_" ) // no initial digits
			.ReplaceFirst( "^##", "Number" ) // assume initial # means number
			.ReplaceAll( "\W", "_" ) // no non-alphanumeric/underscore
			.ReplaceAll( "_{2,}", "_" ); // remove doubled up underscores
	}

	private string function removeAllWhiteSpaceFrom( required string value ){
		return arguments.value.REReplace( "\s+", "", "ALL" );
	}

	/* Common exceptions */
	private void function throwOldExcelFormatException( required string path ){
		Throw( type="cfsimplicity.lucee.spreadsheet.OldExcelFormatException", message="Invalid spreadsheet format", detail="The file #arguments.path# was saved in a format that is too old. Please save it as an 'Excel 97/2000/XP' file or later." );
	}

	private void function throwFileExistsException( required string path ){
		Throw( type=this.getExceptionType(), message="File already exists", detail="The file path #arguments.path# already exists. Use 'overwrite=true' if you wish to overwrite it." );
	}

	private void function throwNonExistentFileException( required string path ){
		Throw( type=this.getExceptionType(), message="Non-existent file", detail="Cannot find the file #arguments.path#." );
	}

	private void function throwUnknownImageTypeException(){
		Throw( type=this.getExceptionType(), message="Could not determine image type", detail="An image type could not be determined from the image provided" );
	}

}

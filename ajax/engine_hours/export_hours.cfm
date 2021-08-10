<cfquery name="engineHours">
    SELECT * ,year(ehDate) AS ehYear
    FROM engine
    LEFT JOIN engine_hours
    ON engine.eID = engine_hours.ehEID
    WHERE eDID = #url.dID#
    ORDER BY eID,ehDate
</cfquery>

<cfquery name="engineInfo" dbtype="query">
    SELECT eID, eName, eMake, eMaxHours
    FROM engineHours
    GROUP BY eID, eName, eMake, eMaxHours
</cfquery>

<cfquery name="dairyName">
    SELECT dCompanyName
    FROM dairies
    WHERE dID = #url.dID#
</cfquery>

<cfset dayEngineHours = {}>
<cfoutput query="engineHours" group="eID">
    <cfset dayEngineHours[eID] = {}>
    <cfset prevDate = ehDate>
    <cfset prevHours = 0>
    
    <cfoutput>
        <cfset daysBetween = dateDiff("d",prevDate,ehDate)>
        <cfif prevHours gt ehHoursTotal>
            <cfset prevHours= 0>
        </cfif>
        <cfset hoursBetween = ehHoursTotal - prevHours>
        <cfset avgHrsPerDay =  (daysBetween != 0) ? hoursBetween/daysBetween : 0>

        <cfloop from="#prevDate#" to="#ehDate#" index="i">
            <cfset dayEngineHours[eID][i] = avgHrsPerDay>
        </cfloop>

        <cfset prevDate = ehDate>
        <cfset prevHours = ehHoursTotal>
    </cfoutput>
</cfoutput>

<head>
</head>
<body>
    <cfset xlTable = {}>

    <cfloop from="2016" to="#year(now())#" index="YR">

        <cfset xlTable["#YR#"] = [["Name","Make","Max Hours","January","February","March",
        "April","May","June","July","August","September","October","November","December"]]>

        <!--- <cfoutput> <h2>#YR#</h2></cfoutput> --->

        <!--- <table border="1">
            <thead>
                <tr>
                    <th>Name</th>
                    <th>Make</th>
                    <th>Max Hours</th>
                    <th>January</th>
                    <th>February</th>
                    <th>March</th>
                    <th>April</th>
                    <th>May</th>
                    <th>June</th>
                    <th>July</th>
                    <th>August</th>
                    <th>September</th>
                    <th>October</th>
                    <th>November</th>
                    <th>December</th>
                </tr>
            <thead> --->
                <cfoutput query="engineInfo">
                <!--- <tr>
                    <td>#eName#</td>
                    <td>#eMake#</td>
                    <td>#eMaxHours#</td> --->
                    <cfset arrayAppend(xlTable["#YR#"],[eName,eMake,eMaxHours])>

                    <cfloop from="1" to="12" index="MO">
                        <cfset startOfMonth = createDate(YR,MO,1)>
                        <cfset endOfMonth = dateAdd('d',-1,dateAdd('m',1,startOfMonth))>
                        <cfset monthHours = 0>
                        <cfloop from="#startOfMonth#" to="#endOfMonth#" index="monthDate">
                            <cfif structKeyExists(dayEngineHours[eID],monthDate)>
                                <cfset monthHours += dayEngineHours[eID][monthDate]>
                            </cfif>
                        </cfloop>
                        <!--- <td>#round(monthHours *100)/100#</td> --->
                        <cfset arrayAppend(xlTable["#YR#"][1 + engineInfo.currentRow],round(monthHours *100)/100)>
                    </cfloop>
                <!--- </tr> --->
            </cfoutput>
        <!--- </table> --->
    </cfloop>

    <cfscript>
        spreadsheet = application.lucee_spreadsheet;
        workbook = spreadsheet.newXlsx("2016");

        for(i = 2016; i <= year(now()); i++)
        {
            if(i > 2016) spreadsheet.createSheet(workbook,"#i#");
            spreadsheet.setActiveSheet(workbook,"#i#");
            spreadsheet.addRows(workbook,xlTable[i]);
        }

        spreadsheet.download(workbook,"#replace(dairyName.dCompanyName[1]," ","_","all")#" & "_engines");
    </cfscript>
</body>
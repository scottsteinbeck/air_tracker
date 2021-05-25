<cfquery name="engineHours">
    SELECT *
    FROM engine
    LEFT JOIN engine_hours
    ON engine.eID = engine_hours.ehEID
    WHERE eDID = 21 AND year(ehDate) = #2017#
</cfquery>

<cfdump var=#engineHours#>

<head>
</head>
<body>
    <table>
        <thead>
            <tr>
                <th>Name</th>
                <th>Make</th>
                <th>Max Hours</th>
                <th>Hours</th>
            </tr>
        <thead>
        <cfoutput query="engineHours">
            <tr>
                <td>#eName#</td>
                <td>#eMake#</td>
                <td>#eMaxHours#</td>
                <td>
                    <cfset yearStart = listToArray(engineHours.min_hours)>
        <cfset lastYearEnd = listToArray(engineHours.previous_max_hours)>
        <cfset yearTotalHours = 0>
        <cfif (yearStart[1] eq 0 and lastYearEnd[1] eq 0) or (max_hours eq 0)>
            <!--- We have no information for this year, this mean the yearEnd is also 0 --->
            <!--- since we have no hours, the hours are 0 --->
            <cfset yearTotalHours = 0>
        <cfelseif (yearStart[1] gt 0 and lastYearEnd[1] eq 0 ) or (yearStart[1] eq lastYearEnd[1]) >
            <!--- we have no previous hours recorded  --->
            <!--- we just need to subtract the end from the start and we have accumulated hours --->
            <cfset yearTotalHours = max_hours - yearStart[1]>
        <cfelse> 
            <!--- we have previous year data so we must find the esimated start of the year engine hours --->
            <cfset daysBetween = dateDiff('d', lastYearEnd[2],yearStart[2])>
            <cfset hoursBetween = yearStart[1] - lastYearEnd[1]>
            <cfset daysSinceFirstOfYear =  dateDiff('d', yearStart[2],setDate)>

            <cfset avgHrsPerDay =  (hoursBetween/daysBetween)>
            <!--- calculate hours from first of year to the year start date --->
            <cfset yearTotalHours = daysSinceFirstOfYear * avgHrsPerDay>
            <!--- calculate elapsed hours during the rest of the year --->
            <cfset yearTotalHours += max_hours - yearStart[1]> 
        </cfif>
                    </td>
            </tr>
        </cfoutput>
    </table>
</body>
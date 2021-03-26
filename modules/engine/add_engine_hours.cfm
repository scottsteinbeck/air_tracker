<cfquery name="engineInfo">
    SELECT *
    FROM engine
    WHERE eID=#url.eID#
</cfquery>

<cfquery name="engineHours">
    SELECT *
    FROM engine_hours
    WHERE ehEID=#url.eID# AND year(ehDate) = #year(url.eDate)#
    ORDER BY ehDate
</cfquery>

<!--- <cfdump var=#engineHours#> --->

<cfset month_hours = [0,0,0,0,0,0,0,0,0,0,0,0]>
<cfset month_acc_hours = duplicate(month_hours)>
<cfif engineHours.RecordCount gt 0>
    <cfset day_hours  = {}>

    <cfset prev_date = min(createDate(2021,1,1),engineHours.ehDate)>
    <cfset prev_hours = engineHours.ehHoursTotal>

    <cfloop query="engineHours">
        <cfset elapsed_engine_hrs = engineHours.ehHoursTotal - prev_hours>
        <cfset elapsed_days = dateDiff('d', prev_date, engineHours.ehDate)>

        <cfset daily_engine_hrs = 0>
        <cfif elapsed_engine_hrs gt 0>
            <cfset daily_engine_hrs = elapsed_engine_hrs/elapsed_days>
        </cfif>
        
        <cfloop index="iDate" from="#prev_date#" to="#engineHours.ehDate#" step="#CreateTimeSpan(1,0,0,0)#">
            <cfset day_hours[dateformat(iDate,'yyyy-mm-dd')] =  round(daily_engine_hrs * 100)/100>
        </cfloop>

        <cfset prev_date = engineHours.ehDate>
        <cfset prev_hours = engineHours.ehHoursTotal>

        <cfif engineHours.currentRow is engineHours.recordcount>
            <cfloop index="iDate" from="#prev_date#" to="#createDate(2021, 12, 31)#" step="#CreateTimeSpan(1,0,0,0)#">
                <cfset day_hours[dateformat(iDate,'yyyy-mm-dd')] =  0>
            </cfloop>
        </cfif>

    </cfloop>
    
    <cfloop collection="#day_hours#" item="iDateKey">
        <cfset month_hours[month(iDateKey)] += day_hours[iDateKey]>
    </cfloop>

    <cfset starting_hours = engineHours.ehHoursTotal>

    <cfloop from="1" to="#month_hours.len()#" index="i">
        <cfset month_acc_hours[i] = starting_hours + month_hours[i]>
        <cfset starting_hours = month_acc_hours[i]>
    </cfloop>
</cfif>


<!--- <cfdump var=#month_acc_hours#> --->
<!--- <cfdump var=#month_hours#> --->
<!--- <cfdump var=#day_hours#> --->

<!--- <cfset hours[12][31] = 0>
<cfset preEHoursTotal = engineHours.eHoursTotal[1]>
<cfoutput query="engineHours">
    <cfset hours[month(engineHours.eDate)][day(engineHours.eDate)]=engineHours.eHoursTotal - preEHoursTotal>
    <cfset hours[month(engineHours.eDate)][day(engineHours.eDate)]=1>
    <cfset preEHoursTotal = engineHours.eHoursTotal>
</cfoutput>--->
<!--- <cfdump var=#arraySum(hoursDsp[1])/eDays#> --->

<cfoutput>
    <form action="index.cfm?action=add_engine_hours">
        <input type="hidden" name="action" value="add_engine_hours">
        <input type="hidden" name="eID" value="#url.eID#"/>
        <!--- <input type="date" value="#url.eDate#" name="eDate"/> --->
        <select name="eDate" onchange="form.submit()">
            <cfloop from="2014" to=#year(now())# index="YR">
                <option value="#LSDateFormat(createDate(YR,1,1),"yyyy-mm-dd")#" <cfif YR eq year(url.eDate)>selected="selected"</cfif>>#YR#</option>
            </cfloop>
        </select>
    </form>
    <table>
        <thead>
        <tr>
            <th>
                Month
            </th>
            <th>
                Monthly total
            </th>
            <th>
                Running total
            </th>
            <th>
                Change Hours
            </th>
        </tr>
        </thead>
        <cfloop from="1" to="12" index="month">
            <tr>
                <cfif engineHours.RecordCount gt 0>
                    <td>#monthAsString(month)#</td>
                    <td>#month_hours[month]#</td>
                    <td>#month_acc_hours[month]#</td>
                    <cfelse>
                    <cfloop from="1" to="3" index="i"><td>---</td></cfloop>
                </cfif>
                <td><input type="number" name="newHours"/></td>
            </tr>
        </cfloop>
    </table>
</cfoutput>
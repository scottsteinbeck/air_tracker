<cfparam name="url.dID" default="1">
<cfparam name="url.year" default="#year(now())#">

<cfset setDate=createDate(url.year,1,1)>
<!--- 
    cy_last_hours_run_entry - Current Year Engine Hours maximum with date 
    cy_first_hours_run_entry - Current Year Engine Hours minimum with date
    py_last_hours_run_entry - Previous Year Engine Hours maximum with date 
--->
<cfquery name="engineInfo">
    SELECT *,
    ifnull((
        SELECT Concat(max(ehHoursTotal),",",max(ehDate))
        FROM engine_hours 
        WHERE ehEID = eID AND year(ehDate)=year(#setDate#)
    ),0) AS cy_last_hours_run_entry,
    ifnull((
        SELECT Concat(min(ehHoursTotal),",",min(ehDate)) 
        FROM engine_hours 
        WHERE ehEID = eID AND year(ehDate)=year(#setDate#)
    ),0) AS cy_first_hours_run_entry,
    ifnull((
        SELECT Concat(max(ehHoursTotal),",",max(ehDate)) 
        FROM engine_hours WHERE ehEID = eID 
        AND year(ehDate)=year(#setDate#)-1
    ),0) AS py_last_hours_run_entry
    FROM engine
    WHERE eDID = #url.dID#
</cfquery>

<cfquery name="DairyList">
    SELECT dID, dCompanyName
    FROM dairies
</cfquery>

<style>
    .stay-top > th{
        position: sticky;
        top: 0;
    }
</style>

    <div class="container-xxl">
        <div class="row mx-0 mt-2 mb-2">
            <div class="col-4">
                <a class="btn btn-outline-primary ml-2 pl-3 pr-3" href="index.cfm?action=add_engine">Add Engine</a>
                <span class="d-none d-lg-inline">
                    <!--- <form action="ajax" --->
                    <cfoutput>
                        <form style="display:inline;" action="ajax/engine_hours/export_hours.cfm">
                            <input type="hidden" name="dID" value="#url.dID#"/>
                            <input style="display:inline;" type="submit" class="btn btn-outline-primary pl-3 pr-3" value="Generate Excel Sheet"/>
                        </form>
                    </cfoutput>
                </span>
            </div>

            <div class="col-5">
                <form action="index.cfm">
                    <input type="hidden" name="action" value="engine_hours">
                    <select name="dID" id="" onchange="form.submit()" class="form-control">  <!--- Dairy Select  --->
						<option value="">none</option>
                        <cfoutput query="DairyList">
                            <option value="#dID#" <cfif url.dID eq dID>selected ="selected"</cfif> >#dCompanyName#</option>
                        </cfoutput>
                    </select>
                </form>
            </div>

			<form action="index.cfm">
				<cfoutput>
					<input type="hidden" name="action" value="engine_hours">
					<input type="hidden" name="dID" value="#url.dID#"/>
					<select name="year" onchange="form.submit()" class="form-control">
						<cfloop from="2014" to=#year(now())# index="YR">
							<option value="#YR#" <cfif YR eq year(setDate)>selected="selected"</cfif>>#YR#</option>
						</cfloop>
					</select>
				</cfoutput>
			</form>
        </div>
    </div>

    <div class="d-none d-lg-block">
        <table class="table">
            <thead class="thead-dark">
                <tr class="stay-top">
                    <th>Name</th>
                    <th>Make</th>
                    <th>Model</th>
                    <th>Max Hours</th>
                    <th>Grower</th>
                    <th>Ranch</th>
                    <th>FamilyHP</th>
                    <th>Permit</th>
                    <th>Location</th>
                    <th>Serial Number</th>
                    <th>Project</th>
                    <cfif session.USer_TYPEID eq 1> <th>Add Hours</th> </cfif>
                    <cfif session.USer_TYPEID eq 2> <th>Vue Hours</th> </cfif>
                </tr>
            </thead>
            <cfoutput query="engineInfo">
                <tr>
                    <cfloop array="#engineInfo.columnArray()#" index="i">
                        <cfif (i eq "eID" or i eq "eTeir" or i eq "eDID" or i eq "max_hours" or i eq "min_hours" or i eq "previous_max_hours")><cfcontinue></cfif>
                        <td>
                            #engineInfo[i][engineInfo.currentRow]#
                        </td>
                    </cfloop>

                    <cfif session.USER_TYPEID eq 1>
                        <td>
                            <a class="btn btn-outline-primary" href="index.cfm?action=add_engine_hours&eID=#engineInfo.eID#&eDate=#LSDateFormat(now(),"yyyy-mm-dd")#">Add Hours</a>
                        </td>
                    </cfif>

                    <cfif session.USer_TYPEID eq 2>
                        <td>
                            <a class="btn btn-outline-primary" href="index.cfm?action=check_engine_hours&eID=#engineInfo.eID#&year=#year(now())#">View Hours</a>
                        </td>
                    </cfif>
                </tr>
            </cfoutput>
        </table>
    </div>
    <!--- 
        Senario 1. No previous or current year data = Total accumulated engine hours used: 0
        Senario 2. No previous, only current year data = whatever is our end - start within the current year
        Sendrio 3. Previous year & current year data = calculate the daily hours and add to the accumulation within the year
        
    --->


    <cfoutput query="engineInfo">
       <cfset currentYearFirst = listToArray(cy_first_hours_run_entry)>
       <cfset currentYearLast = listToArray(cy_last_hours_run_entry)>
       <cfset previousYearLast = listToArray(py_last_hours_run_entry)>

       <cfset yearTotalHours = 0>
        <!--- check to see if we are missing dates --->
        <cfif arrayLen(currentYearFirst) eq 2 and arrayLen(currentYearLast) eq 2>
            <cfset currentYearFirstEngineHours = currentYearFirst[1]>
            <cfset currentYearLastEngineHours = currentYearLast[1]>
            <!--- Accumulated hours elapsed from first to last entries for the year --->
            <cfset yearTotalHours += currentYearLastEngineHours - currentYearFirstEngineHours >
        </cfif>
        <cfif arrayLen(currentYearFirst) eq 2 and arrayLen(previousYearLast) eq 2 >
            <cfset currentYearFirstHoursDate = currentYearFirst[2]>
            <cfset currentYearFirstHours = currentYearFirst[1]>
            <cfset previousYearLastHoursDate = previousYearLast[2]>
            <cfset previousYearLastHours= previousYearLast[1]>
            <cfset firstOfYear = createDate(year(currentYearFirstHoursDate),1,1)>
            <!--- first engine hours taken after the first of the year --->
            <cfif currentYearFirstHoursDate gt createDate(year(currentYearFirstHoursDate),1,1)>
                <!--- get average hours per day between of elapsed hours between last year and this year --->
                <cfset daysBetween = dateDiff('d', previousYearLastHoursDate,currentYearFirstHoursDate)>
                <cfset hoursBetween = currentYearFirstHours - previousYearLastHours>
                <cfset avgHrsPerDay =  (hoursBetween/daysBetween)>

                <cfset daysFromFirstOfYearToStart = dateDiff('d', firstOfYear, currentYearFirstHoursDate)>
                <!--- add on hours accumulated from start of year to first entry in current year--->
                <cfset yearTotalHours += avgHrsPerDay * daysFromFirstOfYearToStart>
            </cfif>
        </cfif>


        <div class="card d-lg-none">
        <div class="card-header text-white bg-secondary py-1 mt-3">
            <div>#engineInfo.eName[engineInfo.currentRow]#</div>
        </div>
            <ul class="list-group list-group-flush">
                <li class="list-group-item py-1 pl-2 text-wrap"><strong>Grower</strong> #engineInfo.eGrower[engineInfo.currentRow]#</li>
                <li class="list-group-item py-1 pl-2 text-wrap"><strong>Ranch</strong> #engineInfo.eRanch[engineInfo.currentRow]#</li>
                <li class="list-group-item py-1 pl-2 text-wrap"><strong>Location</strong> #engineInfo.eLocation[engineInfo.currentRow] ?: "---"#</li>
                <li class="list-group-item py-1 pl-2 text-wrap">
                    <div style="float:right">
                        <cfif session.USer_TYPEID eq 1><a class="btn btn-outline-primary" href="index.cfm?action=add_engine_hours&eID=#engineInfo.eID#&eDate=#LSDateFormat(now(),"yyyy-mm-dd")#">Add Hours</a> </cfif>
                        <cfif session.USer_TYPEID eq 2> <a class="btn btn-outline-primary" href="index.cfm?action=check_engine_hours&eID=#engineInfo.eID#&year=#year(now())#">Vue Hours</a> </cfif>
                    </div>
                    <strong>Max Hours</strong> #decimalFormat(yearTotalHours)# / #engineInfo.eMaxHours[engineInfo.currentRow]#
                    <br/>
                    <progress value="#yearTotalHours#" max=#engineInfo.eMaxHours[engineInfo.currentRow]#></progress>
                </li>
            </ul>
        </div>
    </cfoutput>
    <br>
</div>
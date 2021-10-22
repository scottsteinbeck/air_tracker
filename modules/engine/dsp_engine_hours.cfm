<cfparam name="url.dID" default="1">
<cfset setDate=createDate(2017,1,1)>
<cfquery name="engineInfo">
    SELECT *,
    ifnull((SELECT max(ehHoursTotal) FROM engine_hours WHERE ehEID = eID AND year(ehDate)=year(#setDate#)),0) AS max_hours,
    ifnull((SELECT Concat(min(ehHoursTotal),",",min(ehDate)) FROM engine_hours WHERE ehEID = eID AND year(ehDate)=year(#setDate#)),0) AS min_hours,
    ifnull((SELECT Concat(max(ehHoursTotal),",",max(ehDate)) FROM engine_hours WHERE ehEID = eID AND year(ehDate)=year(#setDate#)-1),0) AS previous_max_hours
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
                            <a class="btn btn-outline-primary" href="index.cfm?action=add_engine_hours&eID=#engineInfo.currentRow#&eDate=#LSDateFormat(now(),"yyyy-mm-dd")#">Add Hours</a>
                        </td>
                    </cfif>

                    <cfif session.USer_TYPEID eq 2>
                        <td>
                            <a class="btn btn-outline-primary" href="index.cfm?action=check_engine_hours&eID=#engineInfo.currentRow#&year=#year(now())#">Vue Hours</a>
                        </td>
                    </cfif>
                </tr>
            </cfoutput>
        </table>
    </div>

    <cfoutput query="engineInfo">
        <cfset yearStart = listToArray(engineInfo.min_hours)>
        <cfset lastYearEnd = listToArray(engineInfo.previous_max_hours)>
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

        <!--- <cfdump var="#dateDiff(engineInfo.min)#"> --->
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
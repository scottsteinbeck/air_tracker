<cfparam name="url.dID" default="1">
<cfparam name="url.year" default="#year(now())#">

<cfset tableData = [
    "eName":"Name", 
    "eMake" : "Make", 
    "eModel" : "Model", 
    "eMaxHours": "Max hours", 
    "eGrower" : "Grower",
    "eRanch" : "Ranch", 
    "eHP" : "HP", 
    "ePermit" : "Permit",
    "eLocation" : "Location", 
    "eSerialNumber" : "Serial Number",
    "eProject" : "Project"
]>

<cfset setDate=createDate(url.year,1,1)>

<!---
    cy_last_hours_run_entry - Current Year Engine Hours maximum with date
    cy_first_hours_run_entry - Current Year Engine Hours minimum with date
    py_last_hours_run_entry - Previous Year Engine Hours maximum with date
--->

<cfquery name="engineInfo">
    SELECT #structKeyList(tableData)#, eID, eDeleteDate, eStartDate, eYearlyTotals
    FROM engine
    WHERE eDID = #url.dID# AND eDeleteDate IS NULL
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
                <cfoutput>
                    <a class="btn btn-outline-primary ml-2 pl-3 pr-3" href="index.cfm?action=add_engine&dID=#url.dID#">Add Engine</a>
                </cfoutput>

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
						<option value="" selected disabled>none</option>
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

    <cfoutput>
        <span class="d-none d-lg-inline">
            <table class="table">
                <thead class="thead-dark">
                    <tr>
                        <cfloop item="colItem" collection="#tableData#">
                            <th>#tableData[colItem]#</th>
                        </cfloop>
                        <th>Current Hours</th>
                        <cfif session.USer_TYPEID eq 1> <th>Add Hours</th> </cfif>
                        <cfif session.USer_TYPEID eq 2> <th>Vue Hours</th> </cfif>
                    </tr>
                </thead>
                    <tbody>
                    <cfloop query="engineInfo">
                        <tr>
                            <cfloop item="colItem" collection="#tableData#">
                                <td>#engineInfo[colItem][engineInfo.currentRow]#</td>
                            </cfloop>

                            <td>
                                <cfset yearTotals = deserializeJSON(engineInfo.eYearlyTotals)>
                                <cfif isStruct(yearTotals) and structKeyExists(yearTotals, url.year)>
                                    <strong>Max Hours</strong> #yearTotals[url.year].service# / #engineInfo.eMaxHours[engineInfo.currentRow]#
                                    <br/>
                                    <progress value="#yearTotals[url.year].service#" max=#engineInfo.eMaxHours[engineInfo.currentRow]#></progress>
                                <cfelse>
                                    No data entered.
                                </cfif>
                            </td>

                            <cfif session.USER_TYPEID eq 1>
                                <td>
                                    <a class="btn btn-outline-primary btn-block" href="index.cfm?action=add_engine_hours&eID=#engineInfo.eID#&eDate=#year(setDate)#">Change / view Hours</a>
                                    <a href="index.cfm?action=add_engine&dID=#url.dID#&eID=#engineInfo.eID#" class="btn btn-outline-primary btn-block">Edit engine</a>
                                </td>
                            </cfif>

                            <cfif session.USer_TYPEID eq 2>
                                <td>
                                    <a class="btn btn-outline-primary" href="index.cfm?action=check_engine_hours&eID=#engineInfo.eID#&year=#year(now())#">View Hours</a>
                                </td>
                            </cfif>
                        </tr>
                    </cfloop>
                </tbody>
            </table>
        </span>
    </cfoutput>

    <!---
        Senario 1. No previous or current year data = Total accumulated engine hours used: 0
        Senario 2. No previous, only current year data = whatever is our end - start within the current year
        Sendrio 3. Previous year & current year data = calculate the daily hours and add to the accumulation within the year

    --->

    <cfoutput query="engineInfo">
        <div class="card d-lg-none">
            <div class="card-header text-white bg-secondary">
                <div>#engineInfo.eName[engineInfo.currentRow]#</div>
            </div>
            <ul class="list-group list-group-flush">
                <li class="list-group-item py-1 pl-2 text-wrap"><strong>Grower</strong> #engineInfo.eGrower[engineInfo.currentRow]#</li>
                <li class="list-group-item py-1 pl-2 text-wrap"><strong>Ranch</strong> #engineInfo.eRanch[engineInfo.currentRow]#</li>
                <li class="list-group-item py-1 pl-2 text-wrap"><strong>Location</strong> #engineInfo.eLocation[engineInfo.currentRow] ?: "---"#</li>
                <li class="list-group-item py-1 pl-2 text-wrap">
                    <div style="float:right">
                        <cfif session.USer_TYPEID eq 1><a class="btn btn-outline-primary" href="index.cfm?action=add_engine_hours&eID=#engineInfo.eID#&eDate=#year(setDate)#">Change / view Hours</a> </cfif>
                        <cfif session.USer_TYPEID eq 2> <a class="btn btn-outline-primary" href="index.cfm?action=check_engine_hours&eID=#engineInfo.eID#&year=#year(now())#">Vue Hours</a> </cfif>
                    </div>
                </li>
            </ul>
        </div>
    </cfoutput>
    <br>
</div>
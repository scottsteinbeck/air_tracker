<cfquery name="engineInfo">
    SELECT *
    FROM engine
    WHERE eID=#url.eID#
</cfquery>

<cfquery name="engineHours">
    SELECT *
    FROM engine_hours
    WHERE ehEID=#url.eID# and YEAR(ehDate)=#url.year#
    ORDER BY ehDate
</cfquery>

<cfoutput>
    <div id="mainVue">


        <div class="row m-2 p-2">
            <!--- Page tital and forward and backward arows --->
            <cfoutput>
                <h4 class="col text-center text-truncate">
                    #engineInfo.eName# engine
                </h4>
            </cfoutput>
        </div>

        <!--- Date dropp down --->
        <div class="row">
            <div class="col-sm-8">
                <div class="input-group mb-3 mt-2 ml-2">
                    <form action="index.cfm" method="GET">
                    <input type="hidden" name="eID" value="#url.eID#">
                    <input type="hidden" name="action" value="check_engine_hours">
                    <select name="year" onchange="form.submit()" class="form-control">
                            <cfloop from="2014" to=#year(now())# index="YR">
                                <option value="#YR#" <cfif YR eq url.year>selected="selected"</cfif>>#YR#</option>
                            </cfloop>
                        </select>
                    </form>
                </div>
            </div>
        </div>

        <!--- Display table --->
        <table class="table table-fixed table-striped">
            <thead>
                <tr>
                    <th width="30%">
                        Months
                    </th>
                    <th width="30%">
                        Month Hours
                    </th>
                    <th width="30%">
                        Total Hours
                    </th>
                </tr>
            </thead>
            <cfloop from="1" to="12" index="month">

            <cfquery name="month_hours" dbtype="query">
                SELECT ehDate,ehHoursTotal
                FROM engineHours
                WHERE MONTH(ehDate)=#month#
            </cfquery>

            <cfquery name="prev_month_hours" dbtype="query">
                SELECT ehDate,ehHoursTotal
                FROM engineHours
                WHERE MONTH(ehDate)=#month - 1#
            </cfquery>
            
                <tr>
                    <td>
                        <!--- month of row --->
                        #monthAsString(month)#
                    </td>
                    <td>
                        <!--- month hours --->
                        <!--- difference between las month and this month hours --->
                        <cfif month_hours.recordCount && isNumeric(month_hours.ehHoursTotal) && isNumeric(prev_month_hours.ehHoursTotal) && month - 1 gt 0>
                            #precisionEvaluate(month_hours.ehHoursTotal - prev_month_hours.ehHoursTotal)#
                        <cfelse>
                            ---
                        </cfif>
                    </td>
                    <td>
                        <!--- total hours --->
                        <cfif month_hours.recordCount>
                            <cfset currentHours = month_hours.ehHoursTotal>
                        <cfelse>
                            <cfset currentHours = "---" >
                        </cfif>
                        #currentHours#
                    </td>
                </tr>
            </cfloop>
        </cfoutput>
    </table>
    <a href="index.cfm?action=engine_hours" class="btn btn-outline-primary ml-2">Engine Hours<a/>
</div>
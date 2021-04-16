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

        <!--- Date dropp down --->
        <form action="index.cfm" method="GET">
        <input type="hidden" name="eID" value="#url.eID#">
        <input type="hidden" name="action" value="check_engine_hours">
        <select name="year" onchange="form.submit()">
                <cfloop from="2014" to=#year(now())# index="YR">
                    <option value="#YR#" <cfif YR eq url.year>selected="selected"</cfif>>#YR#</option>
                </cfloop>
            </select>
        </form>

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
                        <cfif month_hours.recordCount && month - 1 gt 0>
                            #month_hours.ehHoursTotal - prev_month_hours.ehHoursTotal#
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
</div>
<cfquery name="engineInfo">
    SELECT *
    FROM engine
    WHERE eID=#url.eID#
</cfquery>

<cfquery name="engineHours">
    SELECT *
    FROM engine_hours
    WHERE ehID=#url.eID#
</cfquery>

<cfoutput>
    <div id="mainVue">
        <form action="index.cfm" method="GET">
        <input type="hidden" name="eID" value="#url.eID#">
        <input type="hidden" name="action" value="check_engine_hours">
        <select name="year" onchange="form.submit()">
                <cfloop from="2014" to=#year(now())# index="YR">
                    <option value="#YR#" <cfif YR eq url.eDate>selected="selected"</cfif>>#YR#</option>
                </cfloop>
            </select>
        </form>
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
        
            <cfset priviousHours=0>
            <cfloop from="1" to="12" index="month">
                <tr>
                    <td>
                        #monthAsString(month)#
                    </td>
                    <td>
                        <cfif eHoursAtDate(month,engineHours) neq 0 && month - 1 gt 0>
                        #eHoursAtDate(month,engineHours) - eHoursAtDate(month - 1,engineHours)#
                        <cfelse>
                            ---
                        </cfif>
                    </td>
                    <td>
                        <cfif eHoursAtDate(month,engineHours) neq 0>
                            <cfset currentHours = eHoursAtDate(month,engineHours)>
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

<cffunction access="private" returntype="numeric" name="eHoursAtDate">
<cfargument required="true" type="any" name="_month">
<cfargument required="true" type="query" name="_engineHours">
    <cfset hours=0>
    <cfloop query="_engineHours">
        <cfif month(eDate) eq _month>
            <cfset hours = ehHoursTotal>
            <cfbreak/>
        </cfif>
    </cfloop>
<cfreturn hours>
</cffunction>
<cfdump var="#form#">

<cfquery name="DairyTypes">
    select * from cow_types
</cfquery>

<cfloop query ="DairyTypes">
    <cfquery name="InsertCowNumbers">
        insert into Cow_numbers (cnTID, cnYear, cndID, cnQtr1, cnQtr2,cnQtr3, cnQtr4, cnPermitted)
        values  (
            #TID#,
            #form.year#,
            #form.dID#,
            <cfif form["dn_#tID#_Qtr1"] neq ""> #form["dn_#tID#_Qtr1"]#, <cfelse> 0, </cfif>
            <cfif form["dn_#tID#_Qtr2"] neq ""> #form["dn_#tID#_Qtr2"]#, <cfelse> 0, </cfif>
            <cfif form["dn_#tID#_Qtr3"] neq ""> #form["dn_#tID#_Qtr3"]#, <cfelse> 0, </cfif>
            <cfif form["dn_#tID#_Qtr4"] neq ""> #form["dn_#tID#_Qtr4"]#, <cfelse> 0, </cfif>
            <cfif form["dn_#tID#_Permitted"] neq ""> #form["dn_#tID#_Permitted"]# <cfelse> 0 </cfif>
        )
        on duplicate key update
            cnQtr1 = values(cnQtr1),
            cnQtr2 = values(cnQtr2),
            cnQtr3 = values(cnQtr3),
            cnQtr4 = values(cnQtr4),
            cnPermitted = values(cnPermitted)
    </cfquery>
</cfloop>

<cflocation url="index.cfm?action=cow_numbers&dID=#form.dID#" addtoken="false">

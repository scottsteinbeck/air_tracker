<cfdump var="#form#" >
<cfquery name="clearMonths">
    delete from question_months where qID= #form.qID#
</cfquery>
<cfif structKeyExists(form,"months")>
    <cfquery name="insertDairymMonths">
        insert into question_months(qID, mID)
        values  
        <cfloop list="#form.months#" index="mID">
            (#form.qID#, #mID#) 
            <cfif mID neq listLast(form.months)>,</cfif>
        </cfloop>
    </cfquery>
</cfif>
<cflocation url="index.cfm?action=question_months&qID=#form.qID#" addtoken="false">
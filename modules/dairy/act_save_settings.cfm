<cfset selections={}>

<cfloop list="#form.fieldnames#" index="fItem">
    <cfif left(fItem,4) eq "sel_">
        <cfset split=listToArray(fItem, "_")>
        <cfset selections[split[2]]= form[fItem]>
    </cfif> 
</cfloop>

<cfdump var="#selections#">
<cfdump var="#form#">
<cfquery name="clearDairyQuestions">
    delete from dairy_question_link where dID= #form.dID#
</cfquery>

<cfif structKeyExists(form,"questions")>
    <cfquery name="insertDairyQuestions">
        insert into dairy_question_link(dID, qID)
        values
        <cfloop list="#form.questions#" index="qID">
            (#form.dID#, #qID#)
            <cfif qID neq listLast(form.questions)>,</cfif>
        </cfloop>
    </cfquery>
</cfif>
<cflocation url="index.cfm?action=dairy_settings&dID=#form.dID#" addtoken="false">

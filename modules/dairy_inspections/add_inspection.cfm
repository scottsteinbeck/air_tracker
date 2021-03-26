<cfquery name="questionlist">
    select * 
    from questions
    inner join dairy_question_link on dairy_question_link.qID=questions.qID and dID=#form.dID#
        where dairy_question_link.dqType="specific" 
</cfquery>

<!--- <cfdump var="#form#" > --->

<cfif questionlist.recordCount>
    <cfquery name="insertDaysInspected">
        insert ignore into inspections(iqID,iDate,iYear,iMonth,idID)
        values  
        <cfloop query= "questionlist">
            (
                #questionlist.qID#, 
                #createODBCDate(form.inspectionDate)#,
                #form.Year#,
                #form.month#,
                #form.dID#
            ) 
            <cfif questionList.currentRow neq questionlist.recordCount>,</cfif>
        </cfloop>
    </cfquery>
</cfif>
<cflocation url="index.cfm?action=dairy_inspections&dID=#form.dID#&month=#form.month#&year=#form.year#" addtoken="false">
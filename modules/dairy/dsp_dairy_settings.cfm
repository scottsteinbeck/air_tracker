<cfif session.USer_TYPEID eq 2> <cflocation url="/index.cfm?action=dairy_inspections"> </cfif>

<cfparam name="url.dID" default="0">
<cfparam name="url.dqType" default="0">

<cfquery name="dairylist">
    select * from dairies
</cfquery>
<cfquery name="questionlist">
    select * 
    from questions
    left join dairy_question_link on dairy_question_link.qID=questions.qID and dID=#url.dID#
    ORDER BY qPriority
</cfquery>


<form action="index.cfm" method="GET">
    <input type="hidden" name="action" value="dairy_settings">
    <div class="col-sm-10">
        <div class="input-group mb-3 mt-3">
            <select class="form-control" name="dID" id="" onchange="form.submit()">
                <option value="0"> none</option>
                <cfoutput query="dairylist" >
                    <option value="#dID#" <cfif url.dID eq dID>selected ="selected"</cfif> >#dCompanyName#</option>
                </cfoutput>
            </select>
        </div>
    </div>
</form>
<form action="index.cfm?action=act_save_settings" method="POST">
    <input type="hidden" name="dID" value="<cfoutput>#url.dID#</cfoutput>">
    <input type="hidden" name="dqType" value="<cfoutput>#url.dqType#</cfoutput>">
    <input type="hidden" name="action" value="dairy">
    <table class="table" border ="1" style="border-collapse:collapse">
        <thead class="thead-dark">
            <tr>
                <th>Question</th>
                <th>Required</th>
            </tr>
        </thead>
        <tbody>
            <cfoutput query="questionlist" >
            <tr>
                <td><cfif qtype eq "Heading"><h4>#questionlist.qTitle#<h4><cfelse>#questionlist.qNumber# #questionlist.qTitle#</cfif></td>
                <td>
                    <cfif session.USer_TYPEID eq 1>
                    
                        <cfif qtype neq "Heading">
                            <input type="checkbox"  name="questions" value="#questionlist.qID#" <!--- checkboxes for each question that needs to be available on final form --->
                            <cfif questionList.dID is not "">checked ="checked"</cfif>>

                            <select name="sel_#qID#">
                                <option <cfif dqType eq "Daily"> selected = "selected"</cfif> value="Daily">Daily</option>  <!--- if statement is the saving selected results logic--->
                                <option <cfif dqType eq "Weekly"> selected = "selected"</cfif> value="Weekly"> Weekly</option>
                                <option <cfif dqType eq "Specific"> selected = "selected"</cfif> value="specific">Specific</option>
                            </select>
                        </cfif>
                <cfelse>
                    <cfif questionList.dID is not ""><i class="fa fa-6 fa-check"></i></cfif>
                    <cfif dqType eq "Daily">Daily</cfif>
                    <cfif dqType eq "Weekly">Weekly</cfif>
                    <cfif dqType eq "Specific">Specific</cfif>
                </cfif>
            </td>
            </tr>
            </cfoutput>  
        </tbody>
    </table>
    <cfif session.USer_TYPEID eq 1> <input type="submit" value="Save Questions" class="btn btn-outline-primary margin-left" style="margin-bottom: 10px"> </cfif>
</form>
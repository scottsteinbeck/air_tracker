<cfparam name="url.year" default="#year(now())#">
<cfparam name="url.Month" default="#month(now())#">
<cfparam name="url.dID" default="0">
<cfquery name="Dairylist">
    SELECT * FROM Dairies
</cfquery>
<cfquery name="MonthList">
    SELECT * FROM Month_Names
</cfquery>
<cfquery name="inspectionDays">
    SELECT * FROM inspections
</cfquery>
<cfquery name="questionlist">
    SELECT * 
    FROM questions 
    LEFT JOIN dairy_question_link ON dairy_question_link.qID=questions.qID AND dID=#url.dID#
    LEFT JOIN inspections ON idID=#url.dID#
                    AND iYear=#url.Year#
                    AND iMonth=#url.Month#
                    and iqID=questions.qid
                WHERE qType <> "question" OR (qtype = "question" AND dairy_question_link.dID is not null)
        ORDER BY qPriority
</cfquery>


<br>
<!--- Form to get the dairy, month, year that an inspection will be added to--->
<form action="index.cfm" method="GET">
    <input type="hidden" name="action" value="dairy_inspections">
    <div class="container">
        <div class="row">
            <div class="col-sm-8">
                <div class="input-group mb-3">
                    <div class="input-group-prepend">
                    </div>
                    <select name="dID" id="" class="form-control">  <!--- Dairy Select  --->
                        option value="0"> none</option>
                        <cfoutput query="DairyList">
                            <option value="#dID#" <cfif url.dID eq dID>selected ="selected"</cfif> >#dCompanyName#</option>
                        </cfoutput>
                    </select>
                </div>
            </div>

    <div class="col">
    <div class="input-group mb-3">
        <div class="input-group-prepend">
        </div>
        <select name="Month" id="" class="form-control"> <!--- Month Select --->
            <option value="0"> none</option>
            <cfoutput query="monthList" >
                <option value="#mID#" <cfif url.Month eq mID>selected ="selected"</cfif> >#mName#</option>
            </cfoutput>
        </select>
    </div>
    </div>

    <div class="row">
        <div class="input-group mb-3">
            <div class="input-group-prepend">
            </div>
            <select name="year" id="" class="form-control">  <!--- Year Select --->
                <cfoutput>
                    <cfloop from="2017" to="#year(now())#" index="YR">
                        <option value="#YR#" <cfif url.year eq YR>selected ="selected"</cfif> >#YR#</option>
                    </cfloop>
                </cfoutput>
        </select>
    </div>

    <input type="submit" value="change" class="btn btn-outline-primary"></td>
</form>

</div>

<br><br><br><br>

<!--- post form for dID,month, and year values to be recieved from the URL and usde in the inspection
entry  --->
<form action="index.cfm?action=add_inspection" method="POST">
    <input type="hidden" name="action" value="dairy_inspections">
    <input type="hidden" name="dID" value="<cfoutput>#url.dID#</cfoutput>">
    <input type="hidden" name=month value="<cfoutput>#url.Month#"</cfoutput>">
    <input type="hidden" name=year value="<cfoutput>#url.Year#"</cfoutput>">
    <table><tr>
        <td>Inspection Date 
            <input type="Date" Name="InspectionDate" Value="<cfoutput>#dateformat(now(),"yyyy-mm-dd")#</cfoutput>">
</td>

<td><input type="submit" value="add" class="btn btn-outline-primary btn-sm"></td>
</tr></table>
</form>


<table class="table table-hover table-striped" >
    <thead class="thead-dark">
        <tr>
            <th>Question</th>
            <th width=400>Inspection Dates</th>
        </tr>
    </thead>
    <tbody>
        <cfoutput query="questionlist" group="qID" >
        <tr>
            <td class="heading">
                <cfif questionlist.qType is "Heading">
                    <h4>
                        #questionlist.qID#. #questionlist.qTitle#
                    <h4>
                    <cfelse>
                        #questionlist.qID#. #questionlist.qTitle#
                        <br><br>
                </cfif>
                
            <cfoutput>
                <cfif questionlist.qType eq "Documents">
                    <div class="small">
                        #questionlist.qDescription#
                        <a href="http://127.0.0.1:62769/index.cfm?action=dairy_inspections">45 70 Documents</a>
                    </div>
                <cfelse>

                    <cfif questionlist.dqType eq "Specific"> 
                        #dateFormat(questionlist.iDate, "mm-dd-yyyy")# <br>
                    <cfelse> 
                        #questionlist.dqType# 
                    </cfif>
                </cfif>
                
            </cfoutput>


            </td>
            <td>
                <cfif questionlist.qType neq "Heading" && Dairylist.dSummerManure neq 0 && Dairylist.dWinterManure neq 0>
                    <cfset summerDate = createDate(year(now()) , month(Dairylist.dSummerManure) , day(Dairylist.dSummerManure))>
                    <cfset winterDate = createDate(year(now()) , month(Dairylist.dWinterManure) , day(Dairylist.dWinterManure))>
                    #"From " & dateformat(summerDate,"yyyy-mm-dd") & " to " & dateformat(dateadd('d',20,summerDate),"yyyy-mm-dd")#
                    <br><br>
                    #"From " & dateformat(winterDate,"yyyy-mm-dd") & " to " & dateformat(dateadd('d',20,winterDate), "yyyy-mm-dd")#
                </cfif>
            </td>
        </tr>
        </cfoutput>  
    </tbody>
</table>



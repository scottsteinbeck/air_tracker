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
                    AND iqID=questions.qid
                WHERE qType <> "question" OR (qtype = "question" AND dairy_question_link.dID is not null)
        ORDER BY qPriority
</cfquery>
<style>
    .fa-6{
        font-size: 2em;
    }

    .focusOff:focus {
        outline: none;
        box-shadow: none;
    }
</style>

<div id="mainVue">
    <ul class="nav nav-tabs">
        <li class="nav-item">
            <button :class="[(active_tab == 1) ? 'active' : '']" class="nav-link btn focusOff" @click="change_tab(1)">Farm</button>
        </li>
        <li class="nav-item">
            <button :class="[(active_tab == 2) ? 'active' : '']" class="nav-link btn focusOff" @click="change_tab(2)">Documents</button>
        </li>
    </ul>

    <br>
    <!--- Form to get the dairy, month, year that an inspection will be added to--->
    <div class="container">
        <form action="index.cfm" method="GET">
            <input type="hidden" name="action" value="dairy_inspections">
            <div class="row">
                <div class="col-sm-8">
                    <div class="input-group mb-3">
                        <select name="dID" id="" class="form-control">  <!--- Dairy Select  --->
                            <option value="0"> none</option>
                            <cfoutput query="DairyList">
                                <option value="#dID#" <cfif url.dID eq dID>selected ="selected"</cfif> >#dCompanyName#</option>
                            </cfoutput>
                        </select>
                    </div>
                </div>

                <div class="col">
                    <div class="input-group mb-3">
                        <select name="Month" id="" class="form-control"> <!--- Month Select --->
                            <option value="0"> none</option>
                            <cfoutput query="monthList" >
                                <option value="#mID#" <cfif url.Month eq mID>selected ="selected"</cfif> >#mName#</option>
                            </cfoutput>
                        </select>
                    </div>
                </div>

                <div class="col">
                    <div class="input-group">
                        <select name="year" id="" class="form-control">  <!--- Year Select --->
                            <cfoutput>
                                <cfloop from="2017" to="#year(now())#" index="YR">
                                    <option value="#YR#" <cfif url.year eq YR>selected ="selected"</cfif> >#YR#</option>
                                </cfloop>
                            </cfoutput>
                        </select>
                    </div>
                </div>
                <input type="submit" value="change" class="btn btn-outline-primary btn-sm" style="height: 37px">
            </div>
        </form>


    <!--- post form for dID,month, and year values to be recieved from the URL and usde in the inspection
    entry  --->
    <form action="index.cfm?action=add_inspection" method="POST">
        <input type="hidden" name="action" value="dairy_inspections">
        <input type="hidden" name="dID" value="<cfoutput>#url.dID#</cfoutput>">

        <input type="hidden" name=month value="<cfoutput>#url.Month#</cfoutput>">
        <input type="hidden" name=year value="<cfoutput>#url.Year#</cfoutput>">

        <table><tr>
            <td>Inspection Date 
                <input type="Date" Name="InspectionDate" Value="<cfoutput>#dateformat(now(),"yyyy-mm-dd")#</cfoutput>">
    </td>

    <td><input type="submit" value="add" class="btn btn-outline-primary btn-sm"></td>
    </tr></table>
    </form>

    <cfset is_specific=false>
    <cfloop query="questionlist">
        <cfif questionlist.dqType eq "Specific">
            <cfset is_specific=true>
            <cfbreak/>
        </cfif>
    </cfloop>

    <table class="table table-hover table-striped table-bordered" v-if="active_tab == 1">
        <thead class="thead-dark">
            <tr>
                <th>Question</th>
                <th width=70>Day</th>
                <th width=70>Month</th>
                <th width=70>Specific</th>
                <cfif is_specific><th width=300>Recorded dates</th></cfif>
            </tr>
        </thead>
        <tbody>
            <cfoutput query="questionlist" group="qID" >
            <tr>
                <td class="heading">
                    <cfif questionlist.qType is "Heading">
                        <h4>
                            <!--- #questionlist.qID#.---> #questionlist.qTitle#
                        <h4>
                        <cfelse>
                            <!--- #questionlist.qID#. ---> #questionlist.qTitle#
                            <br><br>
                    </cfif>
                    
                <cfoutput>
                    <cfif questionlist.qType eq "Documents">
                        <div class="small">
                            #questionlist.qDescription#
                            <a href="##" @click="change_tab(2)">45 70 Documents</a>
                        </div>
                    </cfif>
                    
                </cfoutput>
                </td>
                <td>
                    <cfif questionlist.dqType eq "Daily"><i class="fa fa-6 fa-check" aria-hidden="true"></i></cfif>
                </td>
                <td>
                    <cfif questionlist.dqType eq "Weekly"><i class="fa fa-6 fa-check" aria-hidden="true"></i></cfif>
                </td>
                <td>
                    <cfif questionlist.dqType eq "Specific"><i class="fa fa-6 fa-check" aria-hidden="true"></i></cfif>
                </td>
                <cfif is_specific>
                    <td>
                        <cfif questionlist.dqType eq "specific">
                            <cfif questionlist.qType neq "Heading" && Dairylist.dSummerManure neq 0 && Dairylist.dWinterManure neq 0>
                                <cfset summerDate = createDate(year(now()) , month(Dairylist.dSummerManure) , day(Dairylist.dSummerManure))>
                                <cfset winterDate = createDate(year(now()) , month(Dairylist.dWinterManure) , day(Dairylist.dWinterManure))>
                                #"From " & dateformat(summerDate,"yyyy-mm-dd") & " to " & dateformat(dateadd('d',20,summerDate),"yyyy-mm-dd")#
                                <br><br>
                                #"From " & dateformat(winterDate,"yyyy-mm-dd") & " to " & dateformat(dateadd('d',20,winterDate), "yyyy-mm-dd")#
                            </cfif>
                        </cfif>
                    </td>
                </cfif>
            </tr>
            </cfoutput>  
        </tbody>
    </table>

        <div v-if="active_tab == 2">
            Hello
        </div>
    </div>
</div>

<script>
    var vue_var = new Vue({
        el: '#mainVue',

        data:{
            active_tab: 1
        },

        methods:{
            change_tab: function(change_tab_val){
                return this.active_tab = change_tab_val;
            }
        }
    });
</script>

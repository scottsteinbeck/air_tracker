    <cfparam name="url.qID" default="0">

    <cfquery name="questionList">
        select * 
        from questions
        order by qPriority , qID
    </cfquery>

    <cfquery name="prevID" dbtype="query">
        select qID
        from questionList
        where qID < #url.qID# and qType != 'Heading'
        Order By qPriority desc , qID desc
    </cfquery>
    
    <cfquery name="nextID" dbtype="query">
        select qID
        from questionList
        where qID > #url.qID# and qType != 'Heading'
        Order By qPriority , qID asc
    </cfquery>


    <cfquery name="activeQuestion" dbtype="query">
        select *
        from questionList
        where qID = #url.qID#
    </cfquery>

    <cfquery name="monthlist" returntype="array">
        select * 
        from month_names
        left join question_months on question_months.mID=month_names.mID
    </cfquery>

    <cfdump var = #monthlist#>

    <!--- Form to get the question id that we're setting the months for --->
    <div class="container-fluid">
        <div class="row m-2 p-2 border">
            <!--- Page tital and forward and backward arows --->
            <cfoutput>
                <cfif prevID.recordCount>
                    <a class="col-1 btn btn-secondary" href="index.cfm?action=question_months&qID=#prevID.qID#" ><<</a>
                <cfelse>
                    <a class="col-1 btn btn-secondary disabled" href="index.cfm?action=question_months&qID=#prevID.qID#" ><<</a>
                </cfif>

                <h4 class="col text-center text-truncate">#activeQuestion.qTitle#<cfif qID is "0">none</cfif></h4>
                
                <cfif nextID.recordCount>
                    <a class="col-1 btn btn-secondary" href="index.cfm?action=question_months&qID=#nextID.qID#">>></a>
                <cfelse>
                    <a class="col-1 btn btn-secondary disabled" href="index.cfm?action=question_months&qID=#nextID.qID#">>></a>
                </cfif>
            </cfoutput>
        </div>
        
        <div class="row m-2">
            <div class="col-sm-9" id="questionContainer" style="height:600px; overflow:auto">
                <!--- Selector with scroll bar --->
                <ul class="list-group list-group-flush">
                    <cfoutput query="questionList">
                        <cfif qType is "Heading">
                        </ul>
                            <h4>#questionList.qTitle#</h4>
                        <ul  class="list-group list-group-flush">
                        <cfelse>
                            <li class="list-group-item <cfif qID eq url.qID>active</cfif>">
                                <a class="btn btn-sm btn-primary <cfif qID eq url.qID>disabled</cfif>" href= "index.cfm?action=question_months&qID=#qID#" > + </a>
                                #questionList.qTitle#
                            </li>
                        </cfif>
                    </cfoutput>
                </ul>
            </div>

        <div class="col-sm-3">
            <div class = "card sticky-top ">
                <div class = "card-body">
                        <!--- Form to send to database of months  --->
                    <form action="index.cfm?action=act_save_months" method="POST">
                        <input type="hidden" name="qID" value="<cfoutput>#url.qID#</cfoutput>">
                        <table>
                            <thead>
                                <tr>
                                    <th>Month Required</th>
                                </tr>
                            </thead>
                            <tbody>
                                <cfoutput query="monthList" >
                                <tr>
                                    <td>
                                        <label>
                                            <input type="checkbox" name="months" value="#monthList.mID#"  <!--- Month checkboxes and saving logic --->
                                            <cfif monthList.qID is not "">checked ="checked"</cfif> >
                                        #monthList.mName#<label></td>
                                    <td></td>
                                </tr>
                                </cfoutput>
                            </tbody>
                        </table>
                        <input type="submit" class="btn btn-outline-primary" value="Save Questions">
                    </form>        
                </div>
            </div>
        </div>
    </div>
</div>
<script>

    questionMonths = new Vue({
        data:{
            activeQID: 0,
        }
        methods:{

        }
    });

    $(document).ready(function () {
        
        var $parentDiv = $('#questionContainer');
        var $innerListItem = $('.list-group-item.active');
        $parentDiv.scrollTop(
            $parentDiv.scrollTop() + 
            $innerListItem.position().top
            - $parentDiv.height()/2 
            + $innerListItem.height()/2
        );
    });
</script>
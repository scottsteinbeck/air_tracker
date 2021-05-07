<cfparam name="url.year" default="#year(now())#">
<cfparam name="url.Month" default="#month(now())#">
<cfparam name="url.dID" default="0">
<cfinclude template="auto_inspection.cfm">
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
                    AND year(iDate)=#url.Year#
                    AND month(iDate)=#url.Month#
                WHERE qType <> "question" OR (qtype = "question" AND dairy_question_link.dID is not null)
        ORDER BY qPriority
</cfquery>

<style>
    .fa-6{
        font-size: 2em;
    }

    .fa-4{
        font-size: 1.5em;
    }

    .focusOff:focus {
        outline: none;
        box-shadow: none;
    }

    .upload-action.is-dragging {
        background: #c5ffd2;
        border-color: #70ff8f;
    }

    .upload-action {
        min-height: 40px;
        border: 2px dashed #ccc;
    }

    file-select > .select-button {
        padding: 1rem;

        color: white;
        background-color: #2EA169;

        border-radius: .3rem;

        text-align: center;
        font-weight: bold;
    }

    .fade-enter-active, .fade-leave-active {
        transition: opacity .5s;
        transition: all 5s ease;
    }
        .fade-enter, .fade-leave-to /* .fade-leave-active below version 2.1.8 */ {
        opacity: 0;
    }

    .stay-top > th{
        position: sticky;
        top: 0;
    }

    .-lucee-dump table{
        border:1px solid #ccc;
        border-collapse: collapse;
    }
    .-lucee-dump table td{
        border: 1px solid #f79494;
        background: #ffc5c5;
        padding: 5px;
        font-size: 10px;
    }
</style>

<div id="mainVue">
    <cfif session.USer_TYPEID eq 1>
        <ul class="nav nav-tabs">
            <li class="nav-item">
                <button :class="[(active_tab == 1) ? 'active' : '']" class="nav-link btn focusOff" @click="change_tab(1)">Farm</button>
            </li>
            <li class="nav-item">
                <button :class="[(active_tab == 2) ? 'active' : '']" class="nav-link btn focusOff" @click="change_tab(2)">Documents</button>
            </li>
        </ul>
    </cfif>

    <br>
    <!--- Form to get the dairy, month, year that an inspection will be added to--->
    <!--- phone vue --->
    <div class="container">
        <div class="d-lg-none">
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
                </div>

                <div class="row">
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
                </div>
                <div class="row">
                    <input type="submit" value="change" class="btn btn-outline-primary btn-sm mt-1 ml-3" style="height: 37px">
                </div>
            </form>
        </div>

        <!--- computer vue --->
        <div class="d-none d-lg-block">
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
                </div>

                <div class="row">
                    <div class="btn-group btn-group-toggle ml-3" data-toggle="buttons">
                        <cfoutput query="monthList">
                            <label class="btn btn-outline-secondary active">
                                <input type="radio" name="Month" value="#mID#" <cfif url.Month eq "#mID#"> checked </cfif>>#mName#</input>
                            </label>
                        </cfoutput>
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
                </div>

                <div class="row">
                    <input type="submit" value="change" class="btn btn-outline-primary btn-sm mt-1 ml-3" style="height: 37px">
                </div>
            </form>
        </div>

        <cfif session.USer_TYPEID eq 1>
            <!--- post form for dID,month, and year values to be recieved from the URL and usde in the inspection
            entry  --->
            <form action="index.cfm?action=add_inspection" method="POST">
                <input type="hidden" name="action" value="dairy_inspections">
                <input type="hidden" name="dID" value="<cfoutput>#url.dID#</cfoutput>">

                <input type="hidden" name=month value="<cfoutput>#url.Month#</cfoutput>">
                <input type="hidden" name=year value="<cfoutput>#url.Year#</cfoutput>">

                <table>
                    <tr>
                        <td>
                            Inspection Date 
                            <input type="Date" Name="InspectionDate" Value="<cfoutput>#dateformat(now(),"yyyy-mm-dd")#</cfoutput>">
                        </td>
                        <td>
                            <input type="submit" value="add" class="btn btn-outline-primary btn-sm">
                        </td>
                    </tr>
                </table>
            </form>
        <cfelse>
            <br>
        </cfif>
    </div>

    <cfset is_specific=false>
    <cfset daily_weekly_set=false>
    <cfset show_M_level_column=(replace(valuelist(questionlist.qShowManurelevel),",","","All") != "")>
    <cfloop query="questionlist">
        <cfif questionlist.dqType eq "Specific">
            <cfset is_specific=true>
        </cfif>
        <cfif questionlist.dqType eq "Daily" or questionlist.dqType eq "Weekly">
            <cfset daily_weekly_set=true/>
        </cfif>
        <cfif is_specific eq true and daily_weekly_set eq true><cfbreak/></cfif>
    </cfloop>


    <cfif isEmpty(lastInspection.lastDate)>
        <cfset newDate=createDate(2017,"01","01")>
    <cfelse>
        <cfset newDate=lastInspection.lastDate>
    </cfif>
    <cfloop condition="newDate lt now()">
        <cfset newDate=dateAdd("d",randRange(80,90),newDate)>
        <cfquery name="addNewDates">
            INSERT
            INTO inspections (iDate,idID,iManureInchConcrete,iManureInchCorral,iManureInchFenceline)
            VALUES (#newDate#,#url.dID#,#randRange(0,3)#,#randRange(2,10)#,#randRange(2,10)#);
        </cfquery>
    </cfloop>
    
    
    <table class="table table-hover table-striped table-bordered" v-if="active_tab == 1">
        <thead class="thead-dark">
            <tr class="stay-top">
                <th>Question</th>
                <cfif daily_weekly_set>
                    <th width=70>Day</th>
                    <th width=70>Weekly</th>
                </cfif>
                <cfif is_specific><th width=300>Recorded dates</th></cfif>
                <cfif show_M_level_column eq true><th width=150>manure level</th></cfif>
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
                                <cfif session.USer_TYPEID eq 1> <a href="##" @click="change_tab(2)">4570 Documents</a> </cfif>
                            </div>
                        </cfif>
                        
                    </cfoutput>
                    </td>

                    <cfif daily_weekly_set>
                        <td>
                            <cfif questionlist.dqType eq "Daily"><i class="fa fa-6 fa-check" aria-hidden="true"></i></cfif>
                        </td>
                        <td>
                            <cfif questionlist.dqType eq "Weekly"><i class="fa fa-6 fa-check" aria-hidden="true"></i></cfif>
                        </td>
                    </cfif>

                    <cfif is_specific>
                        <td>
                            <cfif questionlist.dqType eq "specific">
                                <cfif questionlist.qType neq "Heading" && Dairylist.dSummerManure neq 0 && Dairylist.dWinterManure neq 0>
                                    <cfset summerDate = createDate(year(now()) , month(Dairylist.dSummerManure) , day(Dairylist.dSummerManure))>
                                    <cfset winterDate = createDate(year(now()) , month(Dairylist.dWinterManure) , day(Dairylist.dWinterManure))>
                                    #"From " & dateformat(summerDate,"yyyy-mm-dd") & " to " & dateformat(dateadd('d',20,summerDate),"yyyy-mm-dd")#
                                    <br><br>
                                    #"To " & dateformat(winterDate,"yyyy-mm-dd") & " to " & dateformat(dateadd('d',20,winterDate), "yyyy-mm-dd")#
                                </cfif>
                            </cfif>
                        </td>
                    </cfif>

                    <cfif show_M_level_column>
                        <td>
                            <!--- <cfif isNull(questionlist.qShowManurelevel)> --->
                                <cfif questionlist.qShowManurelevel gt 0>
                                    #dateFormat(questionlist.iDate,"yyyy-mm-dd")#<br>
                                    <cfif questionlist.iManureInchCorral gt 0 && questionlist.qShowManurelevel eq "corral">
                                        Manure #questionlist.iManureInchCorral#"
                                    <cfelseif questionlist.iManureInchConcrete gt 0 && questionlist.qShowManurelevel eq "concrete">
                                        Manure #questionlist.iManureInchConcrete#"
                                    <cfelseif questionlist.iManureInchFenceline gt 0 && questionlist.qShowManurelevel eq "fenceline">
                                        Manure #questionlist.iManureInchFenceline#"
                                    </cfif>
                                </cfif>
                            <!--- </cfif> --->
                        </td>
                    </cfif>
                </tr>
            </cfoutput> 
            
        </tbody>
    </table>
        
    <div v-if="active_tab == 2">
        <div class="row">
            <div class="col-9 offset-md-2">
                <div class="container mt-4">
                    <div class="card text-center">
                        <div class="card-body">
                            <template>
                                <vue-clip :options="options">
                                        <template slot="clip-uploader-action" scope="params">
                                            <div v-bind:class="{'is-dragging': params.dragging}" class="upload-action">
                                            <div class="dz-message"><i class="fa fa-4 fa-file text-muted pt-3 pb-3"></i><h4 style="display: inline;" class="text-muted pt-3 pb-3" > Click or Drag and Drop files here upload </h4></div>
                                            
                                        </div>
                                    </template>
                                
                                    <template slot="clip-uploader-body" scope="props">
                                        <div v-for="file in props.files">
                                            <transition name="fade">
                                                <div v-show="file.progress != 100">
                                                    {{ file.name }} {{ file.status }}
                                                    <progress :value="file.progress" max="100"></progress>
                                                </div>
                                            </transition>
                                        </div>
                                    </template>
                                
                                </vue-clip>
                            </template>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>

<script type="text/javascript" src="node_modules/vue-clip/dist/vue-clip.min.js"></script>

<script>
    var dID = <cfoutput>#url.dID#</cfoutput>;
    var vue_var = new Vue({
        el: '#mainVue',

        data:{
            active_tab: 1,
            options: {
                url: '/ajax/documents/uploader.cfm?dID=' + dID,
                paramName: 'file',
                uploadMultiple:true
            },
            fadeIn: true,
            show: true
        },

        methods:{
            change_tab: function(change_tab_val){
                return this.active_tab = change_tab_val;
            },
        },
    });
</script>

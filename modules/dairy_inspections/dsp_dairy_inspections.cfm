<cfparam name="url.year" default="#year(now())#">
<cfparam name="url.Month" default="#month(now())#">
<cfparam name="url.dID" default="1">
<cfinclude template="auto_inspection.cfm">
<cfquery name="Dairylist">
    SELECT * FROM Dairies
</cfquery>
<cfquery name="MonthList">
    SELECT * FROM Month_Names
	WHERE mName != "all"
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
				WHERE dairy_question_link.dID IS NOT NULL
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
        top: 135px;
    }

	div.stay-top{
		background-color: #ffffff;
		padding: 10px;
		position: sticky;
		top: 0px;
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
	.floatingSig {
		position: absolute;
		top: -38px;
		height: 106px;
		right: 14px;
	}
</style>


<div id="mainVue">

	<!--- Get the active dairy selected by the user. --->
	<cfset activeDairy = "">
	<cfoutput query="DairyList">
		<cfif url.dID eq dID> <cfset activeDairy = dCompanyName></cfif>
	</cfoutput>
	
    <ul class="nav nav-tabs">
        <li class="nav-item">
            <button :class="[(active_tab == 1) ? 'active' : '']" class="nav-link btn focusOff" @click="change_tab(1)">Farm</button>
        </li>
        <li class="nav-item">
            <button :class="[(active_tab == 2) ? 'active' : '']" class="nav-link btn focusOff" @click="change_tab(2)">Documents</button>
        </li>
    </ul>

	<!--- Display the signiture here if on a phone. --->

    <!--- Form to get the dairy, month, year that an inspection will be added to--->
	<div class="stay-top">
		<div class="container">
			
			<!------------------------------------------- phone vue ------------------------------------------->
			<div class="d-lg-none">

				<!--- A forme that contains a dropdown used for selecting the dairy. --->
				<form action="index.cfm" method="GET">
					<input type="hidden" name="action" value="dairy_inspections">
					<div class="row">
						<div class="col-sm-8">
							<div class="input-group mb-3">
								<select name="dID" id="" onchange="form.submit()" class="form-control">  <!--- Dairy Select  --->
									<option value="0"> none</option>
									<cfoutput query="DairyList">
										<option value="#dID#" <cfif url.dID eq dID>selected ="selected"</cfif> >#dCompanyName#</option>
									</cfoutput>
								</select>
							</div>
						</div>
					</div>

					<!--- A dropdown that is used to select the month. --->
					<div class="row">
						<div class="col">
							<div class="input-group mb-3">
								<select name="Month" id="" onchange="form.submit()"  class="form-control"> <!--- Month Select --->
									<cfoutput query="monthList" >
										<option value="#mID#" <cfif url.Month eq mID>selected ="selected"</cfif> >#mName#</option>
									</cfoutput>
								</select>
							</div>
						</div>

						<!--- A dropdown that is used to select the year. --->
						<div class="col">
							<div class="input-group">
								<select name="year" id="" onchange="form.submit()"  class="form-control">  <!--- Year Select --->
									<cfoutput>
										<cfloop from="2017" to="#year(now())#" index="YR">
											<option value="#YR#" <cfif url.year eq YR>selected ="selected"</cfif> >#YR#</option>
										</cfloop>
									</cfoutput>
								</select>
							</div>
						</div>
					</div>
				</form>
			</div>

			<!------------------------------------------- computer vue ------------------------------------------->
			<div class="d-none d-lg-block">

				<!--- A forme that contains a dropdown used for selecting the dairy. --->
				<form action="index.cfm" method="GET">
					<input type="hidden" name="action" value="dairy_inspections">
					<div class="row">
						<div class="col-sm-8">
							<div class="input-group mb-3">
								<select name="dID" id="" onchange="form.submit()"  class="form-control">  <!--- Dairy Select  --->
									<option value="0"> none</option>
									<cfoutput query="DairyList">
										<option value="#dID#" <cfif url.dID eq dID>selected ="selected"</cfif> >#dCompanyName#</option>
									</cfoutput>
								</select>
							</div>
						</div>
					</div>

					<!--- A group of radio buttons that are used to select the month. --->
					<div class="row">
						<div class="btn-group btn-group-toggle ml-3 col-7 align-items-start" data-toggle="buttons">
							<cfoutput query="monthList">
								<label class="btn btn-outline-secondary active">
									<input type="radio" onchange="form.submit()"  name="Month" value="#mID#" <cfif url.Month eq "#mID#"> checked </cfif>>#mName#</input>
								</label>
							</cfoutput>
						</div>

						<!--- A dropdown that is used to select the year. --->
						<div class="col-2">
							<div class="input-group">
								<select name="year" id="" onchange="form.submit()"  class="form-control">  <!--- Year Select --->
									<cfoutput>
										<cfloop from="2017" to="#year(now())#" index="YR">
											<option value="#YR#" <cfif url.year eq YR>selected ="selected"</cfif> >#YR#</option>
										</cfloop>
									</cfoutput>
								</select>
							</div>
						</div>

						<div class="floatingSig">
							<!--- Compare the current date with the date selected by the user where the day is the last day of the month. --->
							<cfif now() gt dateAdd("d", -1, dateAdd("m", 1, createDate(url.year, url.month, 1)))>
								<h4 class="text-center">Signature</h4>
								<!--- If the user did not select a date in the future display the signiture. --->
								<cfoutput> <img src="/images/z_siglist/#activeDairy#.jpg" alt="logo" style="width:200px" class="border p-2"> </cfoutput>
							</cfif>
						</div>
						
					</div>
				</form>
			</div>
			<br>
		</div>
	</div>

    <cfif isEmpty(lastInspection.lastDate)>

		<!--- If their is not previous inspections create one 80 to 90 days after the first day of the first month of 2017. --->
        <cfset newDate=dateAdd("d",randRange(80,90),createDate(2017,"01","01"))>

    <cfelse>

		<!--- If their is already previous inspection dates create another one 80 to 90 days later. --->
        <cfset newDate=dateAdd("d",randRange(80,90),lastInspection.lastDate)>

    </cfif>
	
	<!--- Loop through creating new dates 80 to 90 days apart and create data for those inspections. 
		Stop if the new generated date exceeds the current date. --->
    <cfloop condition="newDate lt now()">
        <cfquery name="addNewDates">
            INSERT INTO inspections (iDate,idID,iManureInchConcrete,iManureInchCorral,iManureInchFenceline,iManureMoisture)
            VALUES (#newDate#,#url.dID#,#randRange(0,3)#,#randRange(2,10)#,#randRange(2,10)#,#randRange(10,49)#);
        </cfquery>
		<cfset newDate=dateAdd("d",randRange(80,90),newDate)>
    </cfloop>
	
	<!--- If their is any data in a row on the qShowOtherData column set the showOtherData to 
		true so that column will be displayed on the table. --->
	<cfset showOtherData=(replace(valuelist(questionlist.qShowOtherData),",","","All") != "")>

	<!--- Set the is_specific variable to true if their are any specific records.
		 If this variable is true display a Recorded dates column.  --->
	<cfset is_specific = "#find("Specific", valuelist(questionlist.qFrequencyType)) gt 0#">

	<!--- Set the daly_weekly_set variable to true if their are any qFrequencyType that are marked as daly or weekly.
		If the daly_weekly_set variable is true create a daly and weekly column. --->
	<cfset daily_weekly_set = 
		"#find("Daily", valuelist(questionlist.qFrequencyType)) gt 0 or find("Weekly", valuelist(questionlist.qFrequencyType)) gt 0#">
	<div v-if="active_tab == 1">
	<table class="table table-hover table-striped table-bordered">

		<!--- Display the correct table headers based on the data from the database. --->
		<thead class="thead-dark">
			<tr class="stay-top">

				<th>Question</th>

				<!--- If their are questions that are daily or weekly display the header for the daily and weekly columns. --->
				<cfif daily_weekly_set>
					<th width=70>Day</th>
					<th width=70>Weekly</th>
				</cfif>

				<!--- If their are spesific questions display the record date header. --->
				<cfif is_specific><th width=300>Recorded dates</th></cfif>

				<cfif showOtherData eq true><th width=150>Other data</th></cfif>

			</tr>
		</thead>

		<!--- Display the columns based on the data from the database. --->
		<tbody>
			<!--- Loop over all the questions to display in the table. --->
			<cfoutput query="questionlist" group="qID" >
				<tr>

					<td class="heading pt-0 pb-0 pl-2">

						<cfif questionlist.qType is "Heading">

							<!--- If this record is a heading display it as a heading. --->
							<h4>#questionlist.qTitle#<h4>

						<cfelse>

							<!--- If the record is not a heading display it as a normle question row --->
							#questionlist.qNumber# #questionlist.qTitle#
							
						</cfif>

						<cfoutput>

							<!--- If the question is a document type display small text under the question. --->
							<cfif questionlist.qType eq "Documents">
								<div class="small">
									#questionlist.qDescription#
									<!--- A link that goes the the documents tab. --->
									<a href="##" @click="change_tab(2)">4570 Documents</a>
								</div>
							</cfif>

						</cfoutput>
					</td>

					<!--- Display the daly and weekly column --->
					<cfif daily_weekly_set>
						<td class="pb-0 pt-1 pl-3">

							<!--- If the question is only suposed to be daly if the month range is from May through October only 
								mark the row as daly if it is between that date range. --->
							<cfif !(find("May through October", questionlist.qTitle)) or
								(find("May through October", questionlist.qTitle) gt 0 and url.Month gte 5 and url.Month lte 10)>
								<!--- If the question is daly mark the row on the daily column with a checkmark. --->
								<cfif questionlist.qFrequencyType eq "Daily"><i class="fa fa-4 fa-check" aria-hidden="true"></i></cfif>
							</cfif>
						
						</td>
						<td class="pb-0 pt-1 pl-3">
							<!--- If the question is weekly mark the row on the weekly column with a checkmark. --->
							<cfif questionlist.qFrequencyType eq "Weekly"><i class="fa fa-4 fa-check" aria-hidden="true"></i></cfif>
						
						</td>
					</cfif>

					<!--- Display data in the Recorded dates column. --->
					<cfif is_specific>
						<td class="pt-0 pb-0 pl-2">

							<!--- If their is a manure level for this row display the date it was recorded. --->
							<cfif questionlist.qShowOtherData neq "">

								#dateFormat(questionlist.iDate,"yyyy-mm-dd")#
							
							<!--- If their was no manure level and if the question requires somthing to be 
								done from May through October display that date range for this year --->
							<cfelseif find("May through October", questionlist.qTitle) gt 0>

								Form: #url.year#-5-1&nbsp;&nbsp;&nbsp;To: #url.year#-10-1

							</cfif>

						</td>
					</cfif>

					<!--- Display a column for the depth of manure if aplicable. --->
					<cfif showOtherData>
						<td class="pt-0 pb-0 pl-2">
							<cfif questionlist.qShowOtherData eq "corral" and questionlist.iManureInchCorral != "">
								Manure level #questionlist.iManureInchCorral#"
							<cfelseif questionlist.qShowOtherData eq "concrete" and questionlist.iManureInchConcrete != "">
								Manure level #questionlist.iManureInchConcrete#"
							<cfelseif questionlist.qShowOtherData eq "fenceline" and questionlist.iManureInchFenceline != "">
								Manure level #questionlist.iManureInchFenceline#"
							<cfelseif questionlist.qShowOtherData eq "moisture" and questionlist.iManureMoisture != "">
								Moisture level #questionlist.iManureMoisture#%
							</cfif>
						</td>
					</cfif>
				</tr>
			</cfoutput>

		</tbody>
	</table>
	<div class="d-lg-none">
		<div class="pb-4 text-center">
			<h4 class="text-center mb-4 border-bottom">Signature</h4>
			<!--- Compare the current date with the date selected by the user where the day is the last day of the month. --->
			<cfif now() gt dateAdd("d", -1, dateAdd("m", 1, createDate(url.year, url.month, 1)))>
				<!--- If the user did not select a date in the future display the signiture. --->
				<cfoutput> <img src="/images/z_siglist/#activeDairy#.jpg" alt="logo" style="width:85%" class=""> </cfoutput>
			</cfif>
		</div>
	</div>
</div>


	<!------------------------------------------- Tab 2 ------------------------------------------->
    <div v-if="active_tab == 2">
        <div class="row">
            <div class="col offset-md-3 mt-3">
                <cfdirectory action="list" directory="user_files/#url.dID#/" recurse="false" name="files4570">
                <cfoutput query="files4570"><a href="user_files/#url.dID#/#files4570.name#">#files4570.name#</a><br></cfoutput>
            </div>
            <cfif session.USer_TYPEID eq 1>
                <div class="col-9 mx-auto">
                    <div class="container mt-4">
                        <div class="card text-center">
                            <div class="card-body">
                                <template>
                                    <vue-clip :options="options">
										<template slot="clip-uploader-action" scope="params">
												<div v-bind:class="{'is-dragging': params.dragging}" class="upload-action">
											<div class="dz-message">
												<i class="fa fa-4 fa-file text-muted pt-3 pb-3"></i>
												<h4 style="display: inline;" class="text-muted pt-3 pb-3" > Click or Drag and Drop files here upload </h4>
											</div>
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
            </cfif>
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
            show: true,

			// dateAndMunureData:
        },

        methods:{
            change_tab: function(change_tab_val){
                return this.active_tab = change_tab_val;
            },
        },
    });
</script>

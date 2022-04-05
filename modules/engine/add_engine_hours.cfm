<cfquery name="engineHours" returntype="ARRAY">
	SELECT *, 'false' as dirty, date_format(ehDate,"%e") as monthday
	FROM engine_hours a
	WHERE a.ehEID = #url.eID# AND ehDeleteDate IS NULL
	order by a.ehDate
</cfquery>

<cfquery name="engineData" returntype="ARRAY">
	SELECT *
	FROM engine
	WHERE eID = #url.eID#
</cfquery>

<!--- <cfdump var="#engineHours#"> --->

<div id="mainVue">
	<div class="row justify-content-center">
		<button class="col-6 btn btn-block btn-outline-primary m-2" :disabled="saveButtonTest == 'Saving...'" style="max-width:150px" @click="saveData(false)">{{saveButtonTest}}</button>
		<button class="col-6 btn btn-block btn-outline-primary m-2" :disabled="saveButtonTest == 'Saving...'" style="max-width:150px" @click="saveData(true)">{{saveButtonTest}} <template v-if="saveButtonTest == 'Save'">and Close</template></button>
		<a href="/index.cfm?action=engine_hours" class="col-3 btn btn-block btn-danger m-2" :disabled="saveButtonTest == 'Saving...'" style="max-width:150px">Cancel</a>
	</div>
	<div class="row justify-content-center text-danger" v-if="!Array.isArray(displaySavingError)">{{displaySavingError}}</div>

	<h4 class="ml-3">Engine data</h4>
	<table class="table">
		<thead>
			<tr>
				<th>Name</th>
				<th>Max hours</th>
				<th>Make</th>
				<th>Model</th>
			</tr>
		</thead>

		<tbody>
			<tr>
				<td> {{engineData.eName}} </td>
				<td> {{engineData.eMaxHours}} </td>
				<td>  {{engineData.eMake}} </td>
				<td>  {{engineData.eModel}} </td>
			</tr>
		</tbody>
	</table>

	<!--- Display data for all years. --->
	<div class="row">
		<div class="col-lg-4" v-for="n in (currentYear - (firstYear - 1))">
			<div class="card mt-4">
				<div class="card-header">
					{{currentYear - n + 1}}
				</div>
				<div class = "card-body">
					<cfoutput>
						<!--- This is all the titles for each column --->
						<div class="row">
							<div class="col-2"></div>

							<div class="col-2 border-left">
								Day
							</div>

							<div class="col-3 border-left">
								Monthly total
							</div>

							<div class="col-2 border-left">
								Power loss
							</div>

							<div class="col-3 border-left">
								Running total
							</div>
						</div>

						<!--- The data is displayed here. --->
						<div class="row mb-2 border" v-for="(month,monthIdx) in months"
							:style="[(months[currentMonth - 1] == months[monthIdx] && n == 1) ? {'background' : '##fdffb8'} : {}]">

							<div class="col-2">
								{{month}}
							
								<br>
								<!--- A button for adding a new entry for the same month. --->
								<button class="btn btn-success btn-sm m-1 float-left" 
									@click="addEntry(monthIdx, n)">+</button>
							</div>

							<div class="col-10">
								<template v-for="(event, eventIndex) in getEvents(monthIdx,(currentYear - n + 1))">
									<div class="row mt-2 mb-2" v-if="!event.deleted">

										<!--- Display the day in a input box. --->
										<div class="col-2 text-center p-0 border-left">
											<input :style="[(event.error != undefined) ? {'border-color': '##d10011'} : {}]" @input="event.dirty = true" type="text" v-model="event.monthday"
											style="width:30px" onclick="$(this).select()">

											<button v-if="months[currentMonth - 1] == months[monthIdx] && n == 1"
												@click="setCurrentDay(event)" class="m-1 btn btn-secondary btn-sm">
												Now
											</button>
										</div>

										<!--- Display the monthly total hours in an input box. --->
										<div class="col-4 text-center p-0  border-left">
											<input @input="event.dirty = true" type="number" v-model="event.ehHoursTotal"
											style="width:80px" onclick="$(this).select()"
											:style="[(calculateHoursRun(event) <= 0 && event.ehHoursTotal == 0) ? {'border-color': '##d10011'} : {}]">

											<!--- A button that allow the to delete records if ther is more than one. --->
											<span v-show="eventIndex > 0">
												<button class="btn btn-danger btn-sm" @click="deleteEngineHours(event)">X</button>
											</span>
										</div>

										<!--- Display a check box that can be selected if the monthly total hours is for power loss. --->
										<div class="col-2 text-center p-0 border-left">
											<input type="checkbox" value="1" v-model="event.ehUseType" @click="event.dirty = true">
										</div>

										<!---
											Display the running total for the year on that month.

											In other words show how many hours the engine has been running since the
											total hours for that engine was entered last.

											This data comes directaly from the query.
										--->
										<div class="col-4 text-center p-0  border-left">
											<span v-if="event.ehMeterChanged == false" :style="[(calculateHoursRun(event) < 0) ? {'color': '##d10011'} : {}]">{{calculateHoursRun(event)}}</span>
											<span v-if="event.ehMeterChanged == true">--</span>

											<button @click="showDetails(event)" class="btn btn-sm btn-secondary ml-1">
												<i class="fas fa-angle-right" v-show="!event.showDetails"></i>
												<i class="fas fa-angle-down" v-show="event.showDetails"></i>
											</button>

											<!--- In the right conditions display a checkbox for settings the engine to a meter change --->
											<div v-show="calculateHoursRun(event) < 0 || event.ehMeterChanged || event.showDetails">
												M/C
												<input type="checkbox" value="1" v-model="event.ehMeterChanged" @click="event.dirty = true">
											</div>
										</div>

										<div class="row">
											<textarea v-model="event.ehTypedNotes" v-on:keyup="checkDirty(event)" type="text" placeholder="Notes" v-show="event.showDetails" class="m-2 ml-3"></textarea>
											<div v-show="!event.showDetails">{{event.ehTypedNotes}}</div>
										</div>

									</div>
								</template>
							</div>
						</div>
					</cfoutput>

					<!--- Display the total the engine has been running for this year. --->
					{{currentYear - n + 1}} Total: {{monthTotals[currentYear - n + 1]["service"] + monthTotals[currentYear - n + 1]["pl"] | toDecimalFormat}}
					<br>
					{{currentYear - n + 1}} Power loss Total: {{monthTotals[currentYear - n + 1]["pl"] | toDecimalFormat}}
					<br>
					{{currentYear - n + 1}} Non power loss total: {{monthTotals[currentYear - n + 1]["service"]}}
				</div>
			</div>
		</div>
	</div>
</div>


<script>
	var lastSaved = JSON.parse(localStorage.getItem("lastSaved"));
	var engineHours = <cfoutput>#serializeJSON(engineHours)#</cfoutput>;
	var startYear = <cfoutput> #(structKeyExists(engineData[1], "eStartDate") && engineData[1].eStartDate != "") ? engineData[1].eStartDate : "2014"# </cfoutput>;
	var engineData = <cfoutput>#serializeJSON(engineData[1])#</cfoutput>
	var urlEID = <cfoutput>#url.eID#</cfoutput>;
	var dateObj = new Date();

	Vue.filter('toDecimalFormat', function (value) {
		if (isNaN( parseFloat(value) )) {
			return value;
		}
		var formatter = new Intl.NumberFormat({
			style: 'decimal',
			minimumFractionDigits: 0,
			maximumFractionDigits: 3,
		});
		return formatter.format(parseFloat(value));
	});

	vueObj = new Vue({
		el: '#mainVue',
		data: {
			months: [
				"Jan",
				"Feb",
				"Mar",
				"Apr",
				"May",
				"Jun",
				"Jul",
				"Aug",
				"Sep",
				"Oct",
				"Nov",
				"Dec"
			],

			currentYear: dateObj.getFullYear(),
			currentMonth: dateObj.getMonth()+1,
			currentDay: dateObj.getDay(),

			firstYear: startYear,

			engineData: engineData,

			// engineHours is an array of structs. It contains all the data for the selected dary for all of time.
			engineHours: lastSaved ? lastSaved: engineHours,
			urlEID: urlEID,

			saveButtonTest: "Save",
			displaySavingError: "",
		},
		computed: {
			dirtyHours: function(){
				var errorFound = undefined;
				var dirtyResolts = this.engineHours.filter( function(x){
					if(x.error != undefined) errorFound = x.error;
					return (x.dirty == true);
				});

				if(errorFound != undefined) return errorFound;
				return dirtyResolts;
			},

			// Sorts the engine hours by their dates.
			engineHoursSorted: function(){
				return this.engineHours.sort(function(a,b){ return new Date(a.ehDate) - new Date(b.ehDate)});
			},

			ehTotals: function(){
				var _self = this;
				var totalsLookup = {};

				for(var i=0; i < _self.engineHoursSorted.length; i++){
					var val = 0;
					var x = _self.engineHoursSorted[i];
					var prevX = _self.engineHoursSorted[i-1];

					if(i > 0 && !x.ehMeterChanged){
						val = x.ehHoursTotal - prevX.ehHoursTotal;
						
						if(x.monthday == prevX.monthday && new Date(x.ehDate).getMonth() == new Date(prevX.ehDate).getMonth()){
							var errorMessage = "Two records can not have the same date."
							x["error"] = errorMessage;
							prevX["error"] = errorMessage;
							break;
						}
						else if(x["error"] != undefined){
							prevX.error = undefined;
						}
					}
					x.error = undefined;
					totalsLookup[x.ehID] = val;
				};

				return totalsLookup;
			},

			engineHoursByDate: function(){
				return this.engineHours.reduce(function(acc,x){
					acc[x.ehDate] = x;
					return acc;
				},{});
			},

			monthTotals: function(){
				var _self = this;
				
				return _self.engineHours.reduce(function(acc,x){
					var dte = new Date(x.ehDate);

					// Check if the year has bean created for when the current hours where entered
					if(!acc.hasOwnProperty(dte.getFullYear())){
						// Add in default year totals
						acc[dte.getFullYear()] = { "pl": 0, "service": 0 };
					}

					var hours = parseFloat((x.ehMeterChanged == 1) ? 0 : _self.calculateHoursRun(x));
					if(hours >= 0){
						if(x.ehUseType == 0){
							acc[dte.getFullYear()]['service'] += hours;
						} else {
							acc[dte.getFullYear()]['pl'] += hours;
						}
					}

					return acc;
				},{});
			},
		},

		methods: {
			checkDirty:function (event) {
				event.dirty = true;
			},
			
			addEntry: function(_month, _year){
				var _self = this;

				var prevEvents = _self.getEvents(_month, _self.currentYear - _year + 1);
				var prevEvent = prevEvents[prevEvents.length - 1];
				var entryDate = new Date(event.ehDate);

				var newEvent = {
					ehDate: prevEvent.ehDate,
					ehEID: prevEvent.ehEID,
					ehHoursTotal: 0,
					ehID: 0,
					ehMeterChanged: 0,
					ehNotes: "",
					ehUseType: 0,
					monthday: +prevEvent.monthday + 1,
					dirty: true,
					showDetails: false
				};

				_self.engineHours.push(newEvent);
			},

			// When the total hours are doubble clicked show the M/C checkbox
			showDetails: function(event){
				var _self = this;

				if(!event.showDetails) { Vue.set(event,"showDetails","true"); }
				else { Vue.delete(event,"showDetails"); }
			},

			// This function filters the data in engineHours and only returns data from the year and
			// the month passed in to it.
			getEvents: function(_month,_year){
				var _self = this;

				// Filter engineHours by the year and the month passed in to the function.
				var filteredEgnHrs = _self.engineHoursSorted.filter(function(x) {
					var dte = new Date(x.ehDate);
					return (dte.getFullYear() == _year && dte.getMonth() == _month);
				});

				// // If filteredEngHrs is empty their is not data yet for that month.
				// if(!filteredEgnHrs.length){
				// 	// If their is no data for that month create a blank data set and add it to engineHours then
				// 	// rerun the function.
				// 	var newEvent = {
				// 		ehDate:new Date(_year, _month, 1),
				// 		ehEID: _self.urlEID,
				// 		ehHoursTotal: 0,
				// 		ehID: 0,
				// 		ehMeterChanged: 0,
				// 		ehNotes: "",
				// 		ehUseType: 0,
				// 		monthday: 1,
				// 		dirty: true
				// 	};
				// 	_self.engineHours.push(newEvent);
				// 	return _self.getEvents(_month,_year);
				// }
				return filteredEgnHrs;
			},

			calculateHoursRun: function(item) {
				var _self = this;

				if(_self.ehTotals.hasOwnProperty(item.ehID)) return Math.round(_self.ehTotals[item.ehID] * 100) / 100;
				return 0;
			},

			setCurrentDay: function(item) { item.monthday = new Date().getDate(); },

			deleteEngineHours: function(item)
			{
				var _self = this;
				
				Vue.set(item,"deleted",true);
				item.dirty = true;
			},

			saveData: function(goBack)
			{
				var _self = this;

				_self.displaySavingError = _self.dirtyHours;
				if(Array.isArray(_self.displaySavingError))
				{
					// console.log("saving");
					_self.saveButtonTest = "Saving..."

					localStorage.setItem("lastSaved",JSON.stringify(this.engineHours));
					$.ajax({
						url: "/modules/engine/save_engine_hours.cfm",
						type: "POST",
						data: { egnHrs: JSON.stringify(_self.displaySavingError), yearlyTotals: JSON.stringify(_self.monthTotals) },
						success: function(res)
						{
							if(res.success){
								localStorage.removeItem("lastSaved");
								if(goBack) window.location = "/index.cfm?action=engine_hours";
								alert("Save successful.");
							}

							_self.saveButtonTest = "Save";
						}
					});
				}
				else{ alert(_self.displaySavingError); }
			},
		},
	});
</script>
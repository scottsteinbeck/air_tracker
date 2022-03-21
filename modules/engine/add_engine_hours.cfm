<cfquery name="engineHours" returntype="ARRAY">
	SELECT *, 'false' as dirty, date_format(ehDate,"%e") as monthday
	FROM engine_hours a
	WHERE a.ehEID = #url.eID# AND ehDeleteDate IS NULL
	order by a.ehDate
</cfquery>

<cfquery name="startYearQry" returntype="ARRAY">
	SELECT eStartDate
	FROM engine
	WHERE eID = #url.eID#
</cfquery>

<!--- <cfdump var="#engineHours#"> --->

<div id="mainVue">
	<div class="row justify-content-center">
		<button class="col-6 btn btn-block btn-outline-primary m-2" :disabled="saveButtonTest == 'Saving...'" style="max-width:150px" @click="saveData(false)">{{saveButtonTest}}</button>
		<button class="col-6 btn btn-block btn-outline-primary m-2" :disabled="saveButtonTest == 'Saving...'" style="max-width:150px" @click="saveData(true)">{{saveButtonTest}} <template v-if="saveButtonTest == 'Save'">and Close</template></button>
	</div>

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
								P/L
							</div>

							<div class="col-3 border-left">
								Running total
							</div>
						</div>

						<!--- The data is displayed here. --->
						<div class="row mb-2 border" v-for="(month,monthIdx) in months"
							:style="[(months[currentMonth - 1] == months[monthIdx] && n == 1) ? {'background' : '##fdffb8'} : {}]">

							<div class="col-2">{{month}}</div>

							<div class="col-10">
								<template v-for="event in getEvents(monthIdx,(currentYear - n + 1))">
									<!--- {{event}} --->
									<div class="row mt-2 mb-2">

										<!--- Display the day in a input box. --->
										<div class="col-2 text-center p-0 border-left">
											<input @input="event.dirty = true" type="text" v-model="event.monthday"
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
										<div class="col-2 text-center p-0  border-left">
											<div v-if="event.ehMeterChanged == false" :style="[(calculateHoursRun(event) < 0) ? {'color': '##d10011'} : {}]">{{calculateHoursRun(event)}}</div>
											<div v-if="event.ehMeterChanged == true">--</div>

											<div v-show="calculateHoursRun(event) < 0">
												M/C
												<input type="checkbox" value="1" v-model="event.ehMeterChanged" @click="event.dirty = true">
											</div>
											
											<div v-show="doesRepeat(event)">
												{{doesRepeat(event)}}
												<button class="btn btn-danger btn-sm" @click="deleteEngineHours(event)">X</button>
											</div>
										</div>
									</div>
								</template>
							</div>
						</div>
					</cfoutput>

					<!--- Display the total the engine has been running for this year. --->
					<span class="pr-2 border-right">Yearly total: {{monthTotals[currentYear - n + 1]["service"] | toDecimalFormat}}</span>
					Yearly P/L total: {{monthTotals[currentYear - n + 1]["pl"]}}
				</div>
			</div>
		</div>
	</div>
</div>


<script>
	var lastSaved = JSON.parse(localStorage.getItem("lastSaved"));
	var engineHours = <cfoutput>#serializeJSON(engineHours)#</cfoutput>;
	var startYear = <cfoutput> #structKeyExists(startYearQry[1], "eStartDate") ? "2014" : startYearQry[1].eStartDate# </cfoutput>;
	var urlEID = <cfoutput>#url.eID#</cfoutput>;
	var dateObj = new Date();

	Vue.filter('toDecimalFormat', function (value) {
		if (isNaN( parseFloat(value) )) {
			console.log(value)
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

			// engineHours is an array of structs. It contains all the data for the selected dary for all of time.
			engineHours: lastSaved ? lastSaved: engineHours,
			urlEID: urlEID,

			saveButtonTest: "Save"
		},
		computed: {
			dirtyHours: function(){ return this.engineHours.filter( function(x){ return (x.dirty == true)}); },

			// Sorts the engine hours by their dates and adds a key prevID to engineHours.
			// If the record if the first one the make the prevID the ehID of the record prevID is being added to.
			engineHoursSorted: function(){
				return this.engineHours
				.sort(function(a,b){ return new Date(a.ehDate) - new Date(b.ehDate)})
				.map(function(x,i,a){
					var prevArrItem = i <= 0 ? 0 : i-1;
					x.prevID = a[prevArrItem].ehID;
					return x;
				});
			},
			engineHoursByID: function(){
				return this.engineHours.reduce(function(acc,x){
					acc[x.ehID] = x;
					return acc;
				},{});
			},

			monthTotals: function(){
				var _self = this;
				return this.engineHours.reduce(function(acc,x){
					var dte = new Date(x.ehDate);
					if(!acc.hasOwnProperty(dte.getFullYear())){
						// Add in default year totals
						acc[dte.getFullYear()] = { "pl": 0, "service": 0 };
					}
					var hours = parseFloat((_self.calculateHoursRun(x) == "--" || x.ehMeterChanged == 1) ? 0 : _self.calculateHoursRun(x));
					if(x.ehUseType == 0){
						acc[dte.getFullYear()]['service'] += hours;
					} else {
						acc[dte.getFullYear()]['pl'] += hours;
					}
					return acc;
				},{});
			},
		},
		methods: {
			// This function filters the data in engineHours and only returns data from the year and
			// the month passed in to it.
			getEvents: function(_month,_year){
				var _self = this;

				// Filter engineHours by the year and the month passed in to the function.
				var filteredEgnHrs = _self.engineHoursSorted.filter(function(x) {
					var dte = new Date(x.ehDate);
					return (dte.getFullYear() == _year && dte.getMonth() == _month);
				});

				// If filteredEngHrs is empty their is not data yet for that month.
				if(!filteredEgnHrs.length){
					// If their is no data for that month create a blank data set and add it to engineHours then
					// rerun the function.
					var newEvent = {
						ehDate:new Date(_year, _month, 1),
						ehEID:_self.urlEID,
						ehHoursTotal:0,
						ehID:0,
						ehMeterChanged:0,
						ehNotes:"",
						ehUseType:0,
						monthday: 1,
						dirty: true
					};
					_self.engineHours.push(newEvent);
					return _self.getEvents(_month,_year);
				}
				return filteredEgnHrs;
			},

			calculateHoursRun: function(item) {
				if(!this.engineHoursByID.hasOwnProperty(item.prevID)) return "--";
				var lastHours = this.engineHoursByID[item.prevID].ehHoursTotal;
				return (item.ehHoursTotal - lastHours).toFixed(2);
			},

			setCurrentDay: function(item) { item.monthday = new Date().getDate(); },

			doesRepeat: function(item){
				if(!this.engineHoursByID.hasOwnProperty(item.prevID) || item.prevID == item.ehID){ return false; }
				// console.log(item);
				var oldID = item.prevID;
				var oldDate = new Date(this.engineHoursByID[oldID].ehDate);
				var newDate = new Date(item.ehDate);
				if(item.ehHoursTotal == 28.2){
					// console.log(item,oldDate.getMonth(), newDate.getMonth());

				}
				return (oldDate.getMonth() == newDate.getMonth());
			},

			deleteEngineHours: function(item)
			{
				var _self = this;
				$.ajax({
					url: "/modules/engine/delete_engine_hours.cfm",
					type: "POST",
					data: { ehID: item.ehID },
					success: function(res)
					{
						if(res.success){
							var itemIndex = _self.engineHours.indexOf(item);
							_self.engineHours.splice(itemIndex,1);
						}
					}
				});
			},

			saveData: function(goBack)
			{
				var _self = this;

				_self.saveButtonTest = "Saving..."

				localStorage.setItem("lastSaved",JSON.stringify(this.engineHours));
				$.ajax({
					url: "/modules/engine/save_engine_hours.cfm",
					type: "POST",
					data: { egnHrs: JSON.stringify(_self.dirtyHours) },
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
			},
		},
	});
</script>
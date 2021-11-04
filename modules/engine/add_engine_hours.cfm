<cfquery name="engineHours" returntype="ARRAY">
	SELECT *, 'false' as dirty, date_format(ehDate,"%e") as monthday,
		(select b.ehID
		from engine_hours b
		where b.ehEID = a.ehEID and b.ehDate < a.ehDate
		order by b.ehDate desc limit 1) as prevID
	FROM engine_hours a
	WHERE a.ehEID = #url.eID#
</cfquery>

<div id="mainVue">
	<button class="btn btn-block btn-outline-primary ml-2" style="max-width:150px" @click="saveData(false)">Save</button>
	<button class="btn btn-block btn-outline-primary ml-2" style="max-width:150px" @click="saveData(true)">Save and Close</button>

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
									<div class="row mt-2 mb-2">

										<!--- Display the day in a input box. --->
										<div class="col-2 text-center p-0 border-left">
											<input @input="event.dirty = true" type="text" v-model="event.monthday"
											style="width:30px" onclick="$(this).select()">

											<button v-if="months[currentMonth - 1] == months[monthIdx] && n == 1"
												@click="setCurrentDay(monthIdx,(currentYear - n + 1))" class="m-1 btn btn-secondary btn-sm">
												Now
											</button>
										</div>

										<!--- Display the monthly total hours in an input box. --->
										<div class="col-4 text-center p-0  border-left">
											<input @input="event.dirty = true" type="text" v-model="event.ehHoursTotal"
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
										</div>
									</div>
								</template>
							</div>
						</div>
					</cfoutput>

					<!--- Display the total the engine has been running for this year. --->
					<span class="pr-2 border-right">Yearly total: {{monthTotals[currentYear - n + 1]["service"]}}</span>
					Yearly P/L total: {{monthTotals[currentYear - n + 1]["pl"]}}
				</div>
			</div>
		</div>
	</div>
</div>

<script>
	var lastSaved = JSON.parse(localStorage.getItem("lastSaved"));
	var engineHours = <cfoutput>#serializeJSON(engineHours)#</cfoutput>;
	var urlEID = <cfoutput>#url.eID#</cfoutput>;
	var dateObj = new Date();

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
			currentMonth: dateObj.getMonth(),
			currentDay: dateObj.getDay(),

			firstYear: 2014,

			// engineHours is an array of structs. It contains all the data for the selected dary for all of time.
			engineHours: lastSaved ? lastSaved: engineHours,
			urlEID: urlEID,
		},
		computed: {
			dirtyHours: function(){ return this.engineHours.filter( function(x){ return (x.dirty == true)}); },

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
					var hours = parseFloat(_self.calculateHoursRun(x));
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
				var filteredEgnHrs = _self.engineHours.filter(function(x) {
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

			setCurrentDay: function(_month,_year)
			{
				this.engineHours.map(function(x){
					var dte = new Date(x.ehDate);
					console.log(dte.getMonth() == _month && dte.getFullYear() == _year);
					if(dte.getMonth() == _month && dte.getFullYear() == _year)
					{
						x = new Date();
					}
				});
			},

			saveData: function(goBack)
			{
				var _self = this;
				localStorage.setItem("lastSaved",JSON.stringify(this.engineHours));
				$.ajax({
					url: "/modules/engine/save_engine_hours.cfm",
					type: "POST",
					data: { egnHrs: JSON.stringify(_self.dirtyHours) },
					success: function(res)
					{
						if(res.success){
							localStorage.removeItem("lastSaved");
							if(goBack) window.location = "/index.cfm?action=dsp_engine_hours";
							alert("Save successful.");
						}
					}
				});
			},
		},
	});
</script>
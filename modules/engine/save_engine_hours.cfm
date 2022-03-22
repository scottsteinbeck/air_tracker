<cfset result={"success": true, "message": ""}>
<cftry>
	
	<cfset egnHrs=deserializeJson(form.egnHrs)>
	
	<cfloop array="#egnHrs#" item="engineData">

		<cfset date = createDate(year(engineData.ehDate),month(engineData.ehDate),engineData.monthDay)>
		<cfset meterChangeCheckbox = (engineData.ehMeterChanged == true) ? 1 : 0>
		<cfset plCheckbox = (engineData.ehUseType == true) ? 1 : 0>

		<cfquery name="addHours">
			INSERT INTO engine_hours (ehID, ehEID, ehDate, ehHoursTotal, ehMeterChanged, ehUseType)
			VALUES (<cfqueryparam value="#engineData.ehID#" cfsqltype="cf_sql_integer">,
				<cfqueryparam value="#engineData.ehEID#" cfsqltype="cf_sql_integer">,
				<cfqueryparam cfsqltype="date" value="#date#">,
				<cfqueryparam value="#engineData.ehHoursTotal#" cfsqltype="cf_sql_double">,
				<cfqueryparam cfsqltype="cf_sql_integer" value="#meterChangeCheckbox#">,
				<cfqueryparam cfsqltype="cf_sql_integer" value="#plCheckbox#">)

			ON DUPLICATE KEY UPDATE
			ehDate = VALUES(ehDate),
			ehHoursTotal = VALUES(ehHoursTotal),
			ehMeterChanged = VALUES(ehMeterChanged),
			ehUseType = VALUES(ehUseType)
		</cfquery>

		<cfquery>
			UPDATE engine
			SET eYearlyTotals = <cfqueryparam value="#yearlyTotals#" cfsqltype="cf_sql_varchar">
			WHERE eID = <cfqueryparam value="#engineData.ehEID#" cfsqltype="cf_sql_integer">
		</cfquery>
	</cfloop>

	<cfcatch>
		<cfheader statuscode="500" statustext="error">
		<cfset result.success = false>
		<cfset result.message = cfcatch>
	</cfcatch>

	<cffinally>
		<cfheader name="Content-Type" value="application/json">
		<cfoutput>#serializeJSON(result)#</cfoutput>
	</cffinally>
</cftry>
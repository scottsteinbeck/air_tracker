<cfset result={"success": true, "message": ""}>
<cftry>
	<!--- <cfdump var=#engineData.ehUseType#> --->
	<cfset egnHrs=deserializeJson(form.egnHrs)>
	<cfloop array="#egnHrs#" item="engineData">
		<cfquery name="addHours">
			INSERT INTO engine_hours (ehID, ehEID, ehDate, ehHoursTotal, ehMeterChanged, ehUseType)
			VALUES (<cfqueryparam value="#engineData.ehID#">,
				<cfqueryparam value="#engineData.ehEID#">,
				<cfqueryparam cfsqltype="date" value="#createDate(year(engineData.ehDate),month(engineData.ehDate),engineData.monthDay)#">,
				<cfqueryparam value="#engineData.ehHoursTotal#">,
				<cfqueryparam value="#engineData.ehMeterChanged ? 1 : 0#">,
				<cfqueryparam value="#engineData.ehUseType ? 1 : 0#">)

			ON DUPLICATE KEY UPDATE
			ehDate = VALUES(ehDate),
			ehHoursTotal = VALUES(ehHoursTotal),
			ehMeterChanged = VALUES(ehMeterChanged),
			ehUseType = VALUES(ehUseType)
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
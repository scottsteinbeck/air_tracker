<cfset result={"success": true, "message": ""}>
<cftry>
	<cfset egnHrs=deserializeJson(form.egnHrs)>
	<cfloop array="#egnHrs#" item="engineData">
		<cfquery name="addHours">
			INSERT INTO engine_hours (ehID, ehEID, ehDate, ehHoursTotal, ehMeterChanged, ehUseType)
			VALUES (<cfqueryparam value="#engineData.ehID#">,
				<cfqueryparam value="#engineData.ehEID#">,
				<cfqueryparam cfsqltype="date" value="#engineData.ehDate#">,
				<cfqueryparam value="#engineData.ehHoursTotal#">,
				<cfqueryparam value="#engineData.ehMeterChanged#">,
				<cfqueryparam value="#engineData.ehUseType#">)

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
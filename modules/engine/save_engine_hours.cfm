<cfset result={"success": true, "message": "", "addedHrsId": {}}>
<cftry>
	<!--- <cfdump var="#yearlyTotals#"/><cfabort/> --->

	<cfset egnHrs=deserializeJson(form.egnHrs)>
	
	<cfif form.keyExists("single")>
		<cfset result.addedHrsId = addHours(egnHrs)>
	<cfelse>
		<cfloop array="#egnHrs#" item="engineData">
			<cfset addHours(engineData)>

			<cfquery>
				UPDATE engine
				SET eYearlyTotals = <cfqueryparam value="#yearlyTotals#" cfsqltype="cf_sql_varchar">
				WHERE eID = <cfqueryparam value="#engineData.ehEID#" cfsqltype="cf_sql_integer">
			</cfquery>
		</cfloop>
	</cfif>

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

<cffunction name="addHours"> 
	<cfargument required="true" type="any" name="engineData">

	<cfset date = createDate(year(engineData.ehDate),month(engineData.ehDate),engineData.monthDay)>
	<cfset meterChangeCheckbox = (engineData.ehMeterChanged == true) ? 1 : 0>
	<cfset plCheckbox = (engineData.ehUseType == true) ? 1 : 0>
	<cfset typedNotes = (engineData.keyExists("ehTypedNotes") ? engineData.ehTypedNotes : "")>
	<!--- <cfset deleteDate = (engineData.keyExists("deleted")) ? now() : "NULL"> --->

	<cfquery result="addHoursDta">
		INSERT INTO engine_hours (ehID, ehEID, ehDate, ehHoursTotal, ehMeterChanged, ehUseType, ehTypedNotes, ehDeleteDate)
		VALUES (<cfqueryparam value="#engineData.ehID#" cfsqltype="cf_sql_integer">,
			<cfqueryparam value="#engineData.ehEID#" cfsqltype="cf_sql_integer">,
			<cfqueryparam cfsqltype="date" value="#date#">,
			<cfqueryparam value="#engineData.ehHoursTotal#" cfsqltype="cf_sql_double">,
			<cfqueryparam cfsqltype="cf_sql_integer" value="#meterChangeCheckbox#">,
			<cfqueryparam cfsqltype="cf_sql_integer" value="#plCheckbox#">,
			<cfqueryparam cfsqltype="cf_sql_varchar" value="#typedNotes#">,
			<cfqueryparam value="#now()#" cfsqltype="cf_sql_date" null="#(!engineData.keyExists("deleted"))#">
		)
		ON DUPLICATE KEY UPDATE
		ehDate = VALUES(ehDate),
		ehHoursTotal = VALUES(ehHoursTotal),
		ehMeterChanged = VALUES(ehMeterChanged),
		ehUseType = VALUES(ehUseType),
		ehTypedNotes = VALUES(ehTypedNotes),
		ehDeleteDate = VALUEs(ehDeleteDate)
	</cfquery>
	<cfif engineData.ehID gt 0>
		<cfreturn engineData.ehID>
	<cfelse>
		<cfreturn addHoursDta.generated_key>
	</cfif>
</cffunction>
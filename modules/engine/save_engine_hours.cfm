<cfset incrementMonth = 0>
<cfif url.ehHoursTotal neq "">
	<cfset incrementMonth = 1>
	<cfquery name="addHours">
		INSERT INTO engine_hours(ehEID,ehHoursTotal,ehDate)
		VALUES (
		<cfqueryparam value="#url.eID#">,
		<cfqueryparam value=#url.ehHoursTotal#>,
		<cfqueryparam value=#url.eDate# sqlType="cf_sql_date">
		)
	</cfquery>
</cfif>
<cflocation url="index.cfm?action=add_engine_hours&eID=#url.eID#&eDate=#
    dateformat(dateadd("m",incrementMonth,url.eDate),"yyyy-mm-dd")#"
    addtoken="false">
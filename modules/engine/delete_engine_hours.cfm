<cfset result={"success": true, "message": ""}>
<cfquery name="deleteHours">
	UPDATE engine_hours
	SET ehDeleteDate = <cfqueryparam cfsqltype="date" value="#now()#">
	WHERE ehID = <cfqueryparam cfsqltype="cf_sql_integer" value="#form.ehID#">
</cfquery>

<cfheader name="Content-Type" value="application/json">
<cfoutput>#serializeJSON(result)#</cfoutput>
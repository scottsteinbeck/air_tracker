<cfdump var="Hello!!!">
<cfquery>
    UPDATE engine
    SET eDeleteDate = <cfqueryparam value="#now()#" cfsqltype="cf_sql_date">
    WHERE <cfqueryparam value="#url.eID#" cfsqltype="cf_sql_integer"> = eID
</cfquery>

<cflocation url="/index.cfm?action=engine_hours&dID=#url.dID#" addtoken="false">
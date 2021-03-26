<cfquery name="addHours">
    INSERT INTO engine_hours(ehEID,ehHoursTotal,ehDate)
    VALUES (
    <cfqueryparam value="#url.eID#">,
    <cfqueryparam value=#url.ehHoursTotal#>,
    <cfqueryparam value=#url.eDate# sqlType="cf_sql_date">
    )
</cfquery>
<cflocation url="index.cfm?action=add_engine_hours&eID=#url.eID#&eDate=#url.eDate#" addtoken="false">
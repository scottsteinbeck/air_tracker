<cfoutput>
    <!--- <cfdump var="#form#"><cfabort> --->

    <cfquery>
        INSERT INTO engine(eName, eMake, eModel, eMaxHours, eGrower, eRanch, eFamilyHP, ePermit, eTeir, eLocation, eSerialNumber, eProject, eDID)
        VALUES (<cfqueryparam value="#form.engineName#" cfsqltype="cf_sql_varchar">,
        <cfqueryparam value="#form.engineMake#" cfsqltype="cf_sql_varchar">,
        <cfqueryparam value="#form.engineModel#" cfsqltype="cf_sql_varchar">,
        <cfqueryparam value="#form.engineMaxHrs#" cfsqltype="cf_sql_integer">,
        <cfqueryparam value="#form.grower#" cfsqltype="cf_sql_varchar">,
        <cfqueryparam value="#form.ranch#" cfsqltype="cf_sql_varchar">,
        <cfqueryparam value="#form.engineFamilyHP#" cfsqltype="cf_sql_varchar">,
        <cfqueryparam value="#form.enginePermit#" cfsqltype="cf_sql_varchar">,
        <cfqueryparam value="#form.engineTeir#" cfsqltype="cf_sql_integer">,
        <cfqueryparam value="#form.engineLocation#" cfsqltype="cf_sql_varchar">,
        <cfqueryparam value="#form.engineSerialNumber#" cfsqltype="cf_sql_integer">,
        <cfqueryparam value="#form.engineProject#" cfsqltype="cf_sql_varchar">,
        <cfqueryparam value="#form.dairyID#" cfsqltype="cf_sql_integer">)
    </cfquery>

<cflocation url="/index.cfm?action=engine_hours&dID=#form.dairyID#" addtoken="false">

</cfoutput>
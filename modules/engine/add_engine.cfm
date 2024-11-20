<cfoutput>
    <!--- <cfdump var="#form#"><cfabort> --->

    <cfif form.keyExists("eID")>

        <cfquery name="oldStartDateQry" returntype="ARRAY">
            SELECT eStartDate
            FROM engine
            WHERE <cfqueryparam value="#form.eID#" cfsqltype="cf_sql_integer"> = eID
        </cfquery>
        <cfset #oldStartDate# = #oldStartDateQry[1].eStartDate#>
        
        <cfif oldStartDate == ""><cfset oldStartDate = "2014"></cfif>
    
        <cfquery>
            UPDATE engine
            SET eName = <cfqueryparam value="#form.engineName#" cfsqltype="cf_sql_varchar">,
                eMake = <cfqueryparam value="#form.engineMake#" cfsqltype="cf_sql_varchar">,
                eModel = <cfqueryparam value="#form.engineModel#" cfsqltype="cf_sql_varchar">,
                eMaxHours = <cfqueryparam value="#form.engineMaxHrs#" cfsqltype="cf_sql_integer">,
                eGrower = <cfqueryparam value="#form.grower#" cfsqltype="cf_sql_varchar">,
                eRanch = <cfqueryparam value="#form.ranch#" cfsqltype="cf_sql_varchar">,
                eHP = <cfqueryparam value="#form.engineHP#" cfsqltype="cf_sql_varchar">,
                eFamily = <cfqueryparam value="#form.engineFamily#" cfsqltype="cf_sql_varchar">,
                ePermit = <cfqueryparam value="#form.enginePermit#" cfsqltype="cf_sql_varchar">,
                eTeir = <cfqueryparam value="#form.engineTeir#" cfsqltype="cf_sql_integer">,
                eLocation = <cfqueryparam value="#form.engineLocation#" cfsqltype="cf_sql_varchar">,
                eSerialNumber = <cfqueryparam value="#form.engineSerialNumber#" cfsqltype="cf_sql_varchar">,
                eProject = <cfqueryparam value="#form.engineProject#" cfsqltype="cf_sql_varchar">,
                eDID = <cfqueryparam value="#form.dairyID#" cfsqltype="cf_sql_integer">,
                eStartDate = <cfqueryparam value="#form.engineStartDate#" cfsqltype="cf_sql_integer">
            WHERE <cfqueryparam value="#form.eID#" cfsqltype="cf_sql_integer"> = eID
        </cfquery>
        
        <cfloop from="#form.engineStartDate#" to="#oldStartDate-1#" index="year">
            <cfloop from="1" to="12" index="month">
                <cfquery>
                    INSERT INTO engine_hours(ehEID, ehHoursTotal, ehDate, ehNotes)
                    VALUES (<cfqueryparam value="#form.eID#" cfsqltype="cf_sql_integer">,
                    0,
                    <cfqueryparam value="#year & "-" & month & "-" & "01"#" cfsqltype="cf_sql_date">,
                    "")
                </cfquery>
            </cfloop>
        </cfloop>

    <cfelse>

        <cfquery result="newEntityData">
            INSERT INTO engine(eName, eMake, eModel, eMaxHours, eGrower, eRanch, eHP, 
                eFamily, ePermit, eTeir, eLocation, eSerialNumber, eProject, eDID, eStartDate)
            VALUES (<cfqueryparam value="#form.engineName#" cfsqltype="cf_sql_varchar">,
            <cfqueryparam value="#form.engineMake#" cfsqltype="cf_sql_varchar">,
            <cfqueryparam value="#form.engineModel#" cfsqltype="cf_sql_varchar">,
            <cfqueryparam value="#form.engineMaxHrs#" cfsqltype="cf_sql_integer">,
            <cfqueryparam value="#form.grower#" cfsqltype="cf_sql_varchar">,
            <cfqueryparam value="#form.ranch#" cfsqltype="cf_sql_varchar">,
            <cfqueryparam value="#form.engineHP#" cfsqltype="cf_sql_varchar">,
            <cfqueryparam value="#form.engineFamily#" cfsqltype="cf_sql_varchar">,
            <cfqueryparam value="#form.enginePermit#" cfsqltype="cf_sql_varchar">,
            <cfqueryparam value="#form.engineTeir#" cfsqltype="cf_sql_integer">,
            <cfqueryparam value="#form.engineLocation#" cfsqltype="cf_sql_varchar">,
            <cfqueryparam value="#form.engineSerialNumber#" cfsqltype="cf_sql_varchar">,
            <cfqueryparam value="#form.engineProject#" cfsqltype="cf_sql_varchar">,
            <cfqueryparam value="#form.dairyID#" cfsqltype="cf_sql_integer">,
            <cfqueryparam value="#form.engineStartDate#" cfsqltype="cf_sql_integer">)
        </cfquery>

        <cfloop from="#form.engineStartDate#" to="#year(now())#" index="year">
            <cfloop from="1" to="12" index="month">
                <cfquery>
                    INSERT INTO engine_hours(ehEID, ehHoursTotal, ehDate, ehNotes)
                    VALUES (<cfqueryparam value="#newEntityData.generatedKey#" cfsqltype="cf_sql_integer">,
                    0,
                    <cfqueryparam value="#year & "-" & month & "-" & "01"#" cfsqltype="cf_sql_date">,
                    "")
                </cfquery>
            </cfloop>
        </cfloop>

    </cfif>

<cflocation url="/index.cfm?action=engine_hours&dID=#form.dairyID#" addtoken="false">

</cfoutput>
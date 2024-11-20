<cfdump var=#form#>
<cfif structKeyExists(form,"id")>
    <cfif form.id eq 0>
    <cfquery name='add_contact'>
        insert ignore into contacts (cID,cFirstName,cLastName,cPhoneNumber)
        values (
            <cfqueryparam value="#form.id#" cfsqltype="cf_sql_integer">,
            <cfqueryparam value="#form.firstName#">,
            <cfqueryparam value="#form.lastName#">,
            <cfqueryparam value="#form.phoneNumber#">
        )
    </cfquery>
    <cfelseif form.id gt 0>
        <cfquery name='add_contact'>
            update contacts set
            cFirstName = <cfqueryparam value="#form.firstName#">,
            cLastName = <cfqueryparam value="#form.lastName#">,
            cPhoneNumber = <cfqueryparam value="#form.phoneNumber#">
            where cID =  <cfqueryparam value="#form.id#" cfsqltype="cf_sql_integer">
        </cfquery>
    </cfif>
    
</cfif>
<cflocation url="contacts.cfm" addtoken="false">
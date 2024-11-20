<cfquery name="delete_contact">
    DELETE 
    FROM contacts
    WHERE cid = <cfqueryparam value="#url.id#" cfsqltype="cf_sql_integer">
</cfquery>
<cflocation url="contacts.cfm" addtoken="false">

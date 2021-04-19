<cfquery name="staff_type" datasource="#application.DSN#" dbtype="ODBC">
SELECT *
FROM user_types
</cfquery>
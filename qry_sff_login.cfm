<cfquery name="staff_login" datasource="#application.DSN#" dbtype="ODBC">
SELECT *, utTitle as staff_position
FROM site_users
Inner Join user_types on utID = suTypeID
WHERE (((lcase(site_users.suUsername))='#lcase(form.user_name)#'));
</cfquery>
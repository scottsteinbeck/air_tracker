<cfif url.keyExists("check")>
    <cfoutput>#session.keyExists("LOGGEDIN")#</cfoutput>
<cfelse>
    <cfset message={"error": ""}>
    <cfinclude template="/qry_sff_login.cfm">
    <!--- <cfdump var="#form.password# #form.user_name#"><cfabort> --->
    <cfif staff_login.recordcount>
        <cfif hash(trim(form.password)) IS trim(staff_login.suPassword)>
            <cfset session.loggedIn="yes">
            <cfset session.user_type = staff_login.staff_position>
            <cfset session.user_typeID = staff_login.suTypeID>
            <cfset session.userid = staff_login.suID>
            <cfset session.display_name = staff_login.suFname & " " & staff_login.suLname>
            <cfset session.user_info = {
                firstname = staff_login.suFname,
                lastname = staff_login.suLname,
                phone = staff_login.suPhone,
                fax = staff_login.suFax,
                address = staff_login.suStreetAddr & " " & staff_login.suCity & ", " & staff_login.suState & " " & staff_login.suZipcode,
                zip = staff_login.suZipcode,
                ccaNum = staff_login.suCCANum,
                pcaNum = staff_login.suPCANum
            }>
        <cfelse>
            <cfset message.error = "Incorrect Password">
        </cfif>
    <cfelse>
        <cfset message.error = "User does not exist">
    </cfif>

    <cfoutput>#serializeJSON(message)#</cfoutput>
</cfif>
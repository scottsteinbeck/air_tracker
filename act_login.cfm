<!DOCTYPE html>
<html>
<head>
  <meta http-equiv="Content-type" content="text/html; charset=utf-8" />
  <title>Agri Mapping Login</title>
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <link rel="icon" type="image/png" href="/favicon.png" />
  <link rel="apple-touch-icon" href="icon.jpg"/>
  <link rel="apple-touch-icon" sizes="72x72" href="icon72.jpg"/>
  <link rel="apple-touch-icon" sizes="114x114" href="icon114.jpg"/>
  <link rel="apple-touch-icon" sizes="144x144" href="icon144.jpg"/>
  <link type="text/css" rel="stylesheet" href="/cssmin/login.min.css" />
  <style>
  @media screen and (max-width: 430px) {
    #login h1#title {
      height: 70px;
      width: 95%;
      background-size: contain;
      background-position: bottom center;
    }
    #login-body .field div {
      width: 95%;
    }
    #login {
      margin: 50px auto;
      width: 95%;
    }
    #login-body input#login_email, #login-body input#login_password{
        display: block;
        float: none;
        position: static;
        width: 95%;
    }
    #login .field .label, #login .checkbox .label, #login .field label, #login .checkbox label {
      width: auto;
    }
  }
  </style>
</head>
<cfinclude template="qry_sff_type.cfm">
<cffunction name="structApply" returntype="Struct">
  <cfargument name="s1" required="true" type="struct">
  <cfargument name="s2" required="true" type="struct">
  <cfloop collection="#s2#" item="sItem">
    <cfif structKeyExists(s1,sItem) and s2[sItem] is not "">
      <cfset s1[sItem] = s2[sItem]>
    </cfif>
  </cfloop>
  <cfreturn s1>
</cffunction>
<cfif isDefined("form.user_name")>
  <cfif isDefined("form.tos")>
    <cfinclude template="qry_sff_login.cfm">
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
            
          <cfset session.homepage = "index.cfm">
<!---
          <cfset session.perm = {nav="",fields=""}>
          <cfif staff_login.utPermissions is not "">
            <cfset session.perm = structApply(session.perm,deserializeJson(staff_login.utPermissions))>
          </cfif>
          <cfif staff_login.suPermissions is not "">
            <cfset session.perm = structApply(session.perm,deserializeJson(staff_login.suPermissions))>
          </cfif> 

          <cfset switchList = structNew()>
          <cfif staff_login.sutypeID eq 3 or staff_login.sutypeID eq 8>
            <cfset session.clientID = staff_login.suID>
            <cfset session.clientName = staff_login.suCompany>
            <!--- <cfset session.perm = {nav="",fields=""}> --->
          <cfelseif staff_login.sutypeID lt 3>
            <cfquery name="fullClientlist" datasource="#application.DSN#">
              SELECT suID, ifNull(suCompany,concat(suFname," ",suLname)) as suCompany FROM site_users where suTypeID = 3
            </cfquery>
            <cfloop query="fullClientList">
              <cfif staff_login.sutypeID is 2 and !getPermission('client_#suID#')>
                <cfcontinue/>
              </cfif>
              <cfset structInsert(switchList,suID,suCompany)>
            </cfloop>
            <cfif staff_login.lastClientID gt 0 and structKeyExists(switchList,staff_login.lastClientID)>
              <cfset session.clientID = staff_login.lastClientID>
              <cfset session.clientName = switchList[staff_login.lastClientID]>
            <cfelse>
              <cfset firstItem = structSort(switchList)[1]>
              <cfset session.clientID = firstItem>
              <cfset session.clientName = switchList[firstItem]>
            </cfif>
          <cfelseif staff_login.sutypeID gt 3 && staff_login.suParentID gt 0>
            <cfquery name="ClientParent" datasource="#application.DSN#">
              SELECT suID, ifNull(suCompany,concat(suFname," ",suLname)) as suCompany FROM site_users where suTypeID = 3 and suID = #staff_login.suParentID#
            </cfquery>
              <cfset session.clientID = ClientParent.suID>
              <cfset session.clientName = ClientParent.suCompany>
          </cfif>
           <cfset session.switchList = switchList>
--->

          <cfset qString = rereplace(cgi.HTTP_REFERER,"http://" & cgi.http_host & "/?(index.cfm)?\??","")>
          <cfif qString does not contain "login" and qString is not "">
            <cflocation url="#cgi.http_referer#" addtoken="No">
          <cfelse>
            <cflocation url="#session.homepage#" addtoken="No">
          </cfif>
      <cfelse>
        <cfset message.error = "Incorrect Password">
      </cfif>
    <cfelse>
      <cfset message.error = "User does not exist">
    </cfif>
  <cfelse>
    <cfset message.error = "Please Accept the Terms Of Service">
  </cfif>
</cfif>



<body >
<div id="login">
	<h1 id="title"><a href="">Agri Mapping</a></h1>
	
  <div id="login-body" class="clearfix"> 
          
  <form action="index.cfm?action=login" name="login" id="login_form" method="post">
    <div class="content_front">
      <div class="pad">
      
        <div class="field">
        <label>Username:</label>
        <div class=""><span class="input"><input name="user_name" id="login_email" class="text" type="text" /></span></div>
        </div> <!-- .field -->
        
        <div class="field">
        <label>Password:</label>
        <div class=""><span class="input"><input name="password" id="login_password" class="text" type="password" value="" /> 
        <a style="" href="index.cfm?action=forgot_password" id="forgot_my_password">Forgot password?</a></span></div>
        </div> <!-- .field -->
        <div class="checkbox">
          <span class="label">&nbsp;</span>
          <div class=""><input name="tos" id="tos" class="checkbox" value="yes" type="checkbox" /> &nbsp;&nbsp;<label style="display: inline;" for="tos">I agree to the <a href="http://www.agritrackingsystems.com/terms-of-service/" target="_blank">terms and conditions</a></label></div>
        </div> <!-- .field -->
        <cfif isDefined("message.error")>
      		<div class="field">
            <label>&nbsp;</label>
            <div class="" style="color:red; font-weight:bold">Error: <cfoutput>#message.error#</cfoutput></div>
          </div> <!-- .field -->
        </cfif>

        
        <div class="field">
        <span class="label">&nbsp;</span>
        <div class=""><button type="submit" class="btn">Login</button></div>
        </div> <!-- .field -->
      </div>
			
    </div>
  </form>
  </div>
  <br/>
    <div class="pad">
    <div class="well">
      If your a new customer click here &nbsp;&nbsp;&nbsp;&nbsp; 
      <a class="btn btn-small btn-green" href="index.cfm?action=create_account">Create An Account</a>
    </div>
  </div>
</div> <!-- #login -->


<style type="text/css">
  .well {
    background-color: #F5F5F5;
    border: 1px solid #E3E3E3;
    box-shadow: 0 1px 1px rgba(0, 0, 0, 0.05) inset;
    margin-bottom: 20px;
    min-height: 20px;
    padding: 10px;
    font-weight: bold;
  }
</style>
</body>
</html>


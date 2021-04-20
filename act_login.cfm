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
  <style>
  html,
  body {
    height: 100%;
  }

  body {
    display: -ms-flexbox;
    display: -webkit-box;
    display: flex;
    -ms-flex-align: center;
    -ms-flex-pack: center;
    -webkit-box-align: center;
    align-items: center;
    -webkit-box-pack: center;
    justify-content: center;
    padding-top: 40px;
    padding-bottom: 40px;
    background-color: #f5f5f5;
  }

  .form-signin {
    width: 100%;
    max-width: 330px;
    padding: 15px;
    margin: 0 auto;
  }
  .form-signin .checkbox {
    font-weight: 400;
  }
  .form-signin .form-control {
    position: relative;
    box-sizing: border-box;
    height: auto;
    padding: 10px;
    font-size: 16px;
  }
  .form-signin .form-control:focus {
    z-index: 2;
  }
  .form-signin input[type="email"] {
    margin-bottom: -1px;
    border-bottom-right-radius: 0;
    border-bottom-left-radius: 0;
  }
  .form-signin input[type="password"] {
    margin-bottom: 10px;
    border-top-left-radius: 0;
    border-top-right-radius: 0;
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
<!--- <div id="login">
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
</div> <!-- #login --> --->

<body class="text-center">
  <form  action="index.cfm?action=login" class="form-signin">
    <img class="mb-4" src="data:image/png;base64,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" alt="" width="72" height="72">
    <h1 class="h3 mb-3 font-weight-normal">Please sign in</h1>
    <label for="user_name" class="sr-only">Email address</label>
    <input type="email" id="user_name" class="form-control" placeholder="Email address" required autofocus>
    <label for="password" class="sr-only">Password</label>
    <input type="password" id="password" class="form-control" placeholder="Password" required>
    <cfif isDefined("message.error")>
      <div class="form-control">
        <label>&nbsp;</label>
        <div class="" style="color:red; font-weight:bold">Error: <cfoutput>#message.error#</cfoutput></div>
      </div> <!-- .field -->
    </cfif>
    <button class="btn btn-lg btn-primary btn-block" type="submit">Sign in</button>
    <p class="mt-5 mb-3 text-muted">&copy; 2017-2018</p>
  </form>
</body>
</html>


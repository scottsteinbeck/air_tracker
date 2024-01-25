<cfparam name="url.action" default="">

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>ATS Air District</title>
    <link rel="stylesheet" href="https://stackpath.bootstrapcdn.com/bootstrap/4.5.2/css/bootstrap.min.css" integrity="sha384-JcKb8q3iqJ61gNV9KGb8thSsNjpSL0n8PARn9HuZOnIxN0hoP+VmmDGMN5t9UJ0Z" crossorigin="anonymous">
    <link rel="stylesheet" href="https://stackpath.bootstrapcdn.com/font-awesome/4.7.0/css/font-awesome.min.css" >
    <script src="https://code.jquery.com/jquery-3.5.1.min.js"></script>
	<script src="https://kit.fontawesome.com/2dced129a9.js" crossorigin="anonymous"></script>

    <style>
        .btn-outline-primary {
            color: #fff;
            background-color: #0082d8;
            border-color: #000000;
        }
        .btn-outline-primary:hover {
            color: #fff;
            background-color: #0096fa;
            border-color: #000000;
        }

        .btn-danger{
            color: #fff;
            background-color: #cc392f;
            border-color: #000000;
        }
        .btn-danger:hover{
            color: #fff;
            background-color: #e84135;
            border-color: #000000;
        }
        .margin-left{
            margin-left: 20px;
        }
    </style>

    <script src="https://cdn.jsdelivr.net/npm/vue@2.6.12/dist/vue.js"></script>
</head>
<body>
    <cfparam name="session.dID" default="0">
    <cfif structKeyExists(url,"dID")>
        <cfset session.dID = url.dID>
    <cfelse>
        <cfset url.dID = session.dID>
    </cfif>

	<cfquery name="dairyName">
		SELECT dID, dCompanyName
		FROM dairies
		WHERE dID = #url.dID#
	</cfquery>

    <cfif structKeyExists(session,"loggedin")>
        <cfinclude template="navigation.cfm">
    <cfelse>
        <cfset url.action="login">
    </cfif>

	<!--- <cfdump var=#url#> --->
	<cfif url.action != "question_months" && url.action != "login">
		<h2 class="d-flex justify-content-center"><cfoutput>#dairyName.dCompanyName#</cfoutput></h2>
	</cfif>


    <cfswitch expression="#url.action#">
        <cfcase value="dairy_settings"><cfinclude template="modules/dairy/dsp_dairy_settings.cfm"></cfcase>
        <cfcase value="act_save_settings"><cfinclude template="modules/dairy/act_save_settings.cfm"></cfcase>
        <cfcase value="question_months"><cfinclude template="modules/questions/dsp_question_months.cfm"></cfcase>
        <cfcase value="act_save_months"><cfinclude template="modules/questions/act_save_months.cfm"></cfcase>
        <cfcase value="dairy_inspections"><cfinclude template="modules/dairy_inspections/dsp_dairy_inspections.cfm"></cfcase>
        <cfcase value="act_save_inspections"><cfinclude template="modules/dairy_inspections/act_save_inspections.cfm"></cfcase>
        <cfcase value="add_inspection"><cfinclude template="modules/dairy_inspections/add_inspection.cfm"></cfcase>
        <cfcase value="Cow_numbers"><cfinclude template="modules/CowNumbers/dsp_cow_numbers.cfm"></cfcase>
        <cfcase value="act_save_numbers"><cfinclude template="modules/CowNumbers/act_save_numbers.cfm"></cfcase>
        <cfcase value="engine_hours"><cfinclude template="modules/engine/dsp_engine_hours.cfm"></cfcase>
        <cfcase value="add_engine_hours"><cfinclude template="modules/engine/add_engine_hours.cfm"/></cfcase>
        <cfcase value="add_engine"><cfinclude template="modules/engine/dsp_add_engine.cfm"/></cfcase>
        <cfcase value="delete_engine"><cfinclude template="modules/engine/delete_engine.cfm"/></cfcase>
        <cfcase value="save_engine_hours"><cfinclude template="modules/engine/save_engine_hours.cfm"/></cfcase>
        <cfcase value="check_engine_hours"><cfinclude template="modules/engine/check_engine_hours.cfm"/></cfcase>
        <cfcase value="dsp_documents"><cfinclude template="modules/dairy_inspections/dsp_documents.cfm"/></cfcase>
        <cfcase value="login"><cfinclude template="act_login.cfm"/></cfcase>
        <cfcase value="logout"><cfinclude template="act_logout.cfm"/></cfcase>
        <cfdefaultcase>
            <cfinclude template="modules/dairy_inspections/dsp_dairy_inspections.cfm">
        </cfdefaultcase>
    </cfswitch>
    <script src="https://cdn.jsdelivr.net/npm/popper.js@1.16.1/dist/umd/popper.min.js" integrity="sha384-9/reFTGAW83EW2RDu2S0VKaIzap3H66lZH81PoYlFhbGU+6BZp6G7niu735Sk7lN" crossorigin="anonymous"></script>
    <script src="https://stackpath.bootstrapcdn.com/bootstrap/4.5.2/js/bootstrap.min.js" integrity="sha384-B4gt1jrGC7Jh4AgTPSdUtOBvfO8shuf57BaghqFfPlYxofvL8/KUEfYiJOMMV+rV" crossorigin="anonymous"></script>
</body>
</html>


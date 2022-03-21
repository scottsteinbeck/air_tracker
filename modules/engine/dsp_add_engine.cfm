<cfif session.USER_TYPEID eq 1>

    <cfif url.keyExists("eID")>
        <cfquery name="engine">
            SELECT *
            FROM engine
            WHERE <cfqueryparam value="#url.eID#" cfsqltype="cf_sql_integer"> = eID
        </cfquery>

        <cfset submitButton = "Update entity">
        
    <cfelse>

        <cfset engine.eName = "">
        <cfset engine.eMake = "">
        <cfset engine.eModel = "">
        <cfset engine.eMaxHours = "">
        <cfset engine.eRanch = "">
        <cfset engine.eHP = "">
        <cfset engine.ePermit = "">
        <cfset engine.eTeir = "">
        <cfset engine.eLocation = "">
        <cfset engine.eSerialNumber = "">
        <cfset engine.eProject = "">
        <cfset engine.eFamily = "">
        <cfset engine.eStartDate = "2014">

        <cfset submitButton = "Create engine">

    </cfif>

    <cfoutput>
        <div class="container">
            <form method="POST" action="modules/engine/add_engine.cfm" class="form">
                <div class="form-group">
                    <label>Engine name</label>
                    <input type="text" name="engineName" class="form-control" value="#engine.eName#">
                </div>

                <div class="form-group">
                    <label>Engine make</label>
                    <input type="text" name="engineMake" class="form-control" value="#engine.eMake#">
                </div>

                <div class="form-group">
                    <label>Engine model</label>
                    <input type="text" name="engineModel" class="form-control" value="#engine.eModel#">
                </div>

                <div class="form-group">
                    <label>Max hours</label>
                    <input type="number" name="engineMaxHrs" class="form-control" value="#engine.eMaxHours#">
                </div>

                <div class="form-group">
                    <label>Ranch</label>
                    <input type="text" name="ranch" class="form-control" value="#engine.eRanch#">
                </div>

                <div class="form-group">
                    <label>Engine HP</label>
                    <input type="text" name="engineHP" class="form-control" value="#engine.eHP#">
                </div>

                <div class="form-group">
                    <label>Engine family</label>
                    <input type="text" name="engineFamily" class="form-control" value="#engine.eFamily#">
                </div>

                <div class="form-group">
                    <label>Engine permit</label>
                    <input type="text" name="enginePermit" class="form-control" value="#engine.ePermit#">
                </div>

                <div class="form-group">
                    <label>Engine teir</label>
                    <input type="number" name="engineTeir" class="form-control" value="#engine.eTeir#">
                </div>

                <div class="form-group">
                    <label>Engine location</label>
                    <input type="text" name="engineLocation" class="form-control" value="#engine.eLocation#">
                </div>

                <div class="form-group">
                    <label>Engine serial number</label>
                    <input type="text" name="engineSerialNumber" class="form-control" value="#engine.eSerialNumber#">
                </div>
                
                <div class="form-group">
                    <label>Engine Project</label>
                    <input type="text" name="engineProject" class="form-control" value="#engine.eProject#">
                </div>

                <div class="form-group">
                    <label>Starting year</label>
                    <select class="form-control" name="engineStartDate">
                        <cfloop from="2014" to="#year(now())#" index="year">
                            <option value="#year#" <cfif "#engine.eStartDate#" == "#year#">selected</cfif>>
                                #year#
                            </option>
                        </cfloop>
                    </select>
                </div>
                
                <input type="hidden" name="grower" value="#dairyName.dCompanyName#">

                <input type="hidden" name="dairyID" value="#url.dID#">

                <cfif url.keyExists('eID')>
                    <input type="hidden" name="eID" value="#url.eID#">
                </cfif>
                
                <input type="submit" value="#submitButton#" class="btn btn-outline-primary mb-3">
                <a href="index.cfm?action=engine_hours&dID=#url.dID#" class="btn btn-danger mb-3">Cancel</a>
                <cfif url.keyExists('eID')> <a href="index.cfm?action=delete_engine&eID=#url.eID#&dID=#url.dID#" class="btn btn-danger mb-3 float-right">Delete engine</a></cfif>
            </form>
        </div>
    </cfoutput>
</cfif>
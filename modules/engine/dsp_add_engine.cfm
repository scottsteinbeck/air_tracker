<cfoutput>
    <div class="container">
        <form method="POST" action="modules/engine/add_engine.cfm" class="form">
            <div class="form-group">
                <label>Engine name</label>
                <input type="text" name="engineName" class="form-control">
            </div>

            <div class="form-group">
                <label>Engine make</label>
                <input type="text" name="engineMake" class="form-control">
            </div>

            <div class="form-group">
                <label>Engine model</label>
                <input type="text" name="engineModel" class="form-control">
            </div>

            <div class="form-group">
                <label>Max hours</label>
                <input type="number" name="engineMaxHrs" class="form-control">
            </div>

            <div class="form-group">
                <label>Ranch</label>
                <input type="text" name="ranch" class="form-control">
            </div>

            <div class="form-group">
                <label>Engine HP</label>
                <input type="text" name="engineHP" class="form-control">
            </div>

            <div class="form-group">
                <label>Engine family</label>
                <input type="text" name="engineFamily" class="form-control">
            </div>

            <div class="form-group">
                <label>Engine permit</label>
                <input type="text" name="enginePermit" class="form-control">
            </div>

            <div class="form-group">
                <label>Engine teir</label>
                <input type="number" name="engineTeir" class="form-control">
            </div>

            <div class="form-group">
                <label>Engine location</label>
                <input type="text" name="engineLocation" class="form-control">
            </div>

            <div class="form-group">
                <label>Engine serial number</label>
                <input type="text" name="engineSerialNumber" class="form-control">
            </div>
            
            <div class="form-group">
                <label>Engine Project</label>
                <input type="text" name="engineProject" class="form-control">
            </div>

            <input type="hidden" name="grower" value="#dairyName.dCompanyName#"></input>

            <input type="hidden" name="dairyID" value="#url.dID#">
            
            <input type="submit" value="Create engine" class="btn btn-outline-primary mb-3">
            <a href="index.cfm?action=engine_hours&dID=#url.dID#" class="btn btn-danger mb-3">Cancel</a>
        </form>
    </div>
</cfoutput>
<cfquery name="engineInfo">
    SELECT eName,eMake,eModel,eMaxHours,eGrower,eRanch,eFamilyHP,ePermit,ePermit,eTeir,eLocation,eSerialNumber,eProject FROM engine
</cfquery>

<!--- <cfquery name="addEngine">
    INSERT 
    INTO engine(eID,eName,eGrower)
    VALUE (0,"Test Name","Test Grower");
</cfquery> --->

<!--- <cfdump var=#engineInfo#> --->

<a href="index.cfm?action=add_engine">Add Engine</a>

<table class="table">
    <thead class="thead-dark">
        <th>Engine Name</th>
        <th>Engine Make</th>
        <th>Engine Model</th>
        <th>Engine Max Hours</th>
        <th>Engine Grower</th>
        <th>Engine Ranch</th>
        <th>Engine FamilyHP</th>
        <th>Engine Permit</th>
        <th>Engine Permit</th>
        <th>Engine Location</th>
        <th>Engine Serial Number</th>
        <th>Engine Project</th>
        <th>Add Hours</th>
        <th>Vue Hours</th>
    </thead>
    <cfoutput query="engineInfo">
        <tr>
            <cfloop array="#engineInfo.columnArray()#" index="i">
                <td>
                    #engineInfo[i][engineInfo.currentRow]#
                </td>
            </cfloop>
            <td>
                <a href="index.cfm?action=add_engine_hours&eID=#engineInfo.currentRow#&eDate=#LSDateFormat(now(),"yyyy-mm-dd")#">Add Hours</a>    
            </td>
            <td>
            <a href="index.cfm?action=check_engine_hours&eID=#engineInfo.currentRow#&eDate=#LSDateFormat(now(),"yyyy-mm-dd")#">Vue Hours</a>
            </td>
        </tr>
    </cfoutput>
</table>

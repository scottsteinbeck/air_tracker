<cfloop list="#form.fieldnames#" index="fieldname">
    <cfif left(fieldname,4) is not "file"><cfcontinue></cfif>
    <cfset path="../../user_files/#url.dID#">
    <cfif (!directoryExists(expandPath(path)))>
        <cfset directoryCreate(path)>
    </cfif>
    <cffile action="upload" destination="#expandPath(path)#" filefield="form.#fieldname#" nameconflict="makeunique">
</cfloop>
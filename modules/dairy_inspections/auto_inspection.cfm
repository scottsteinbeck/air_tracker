<cfquery name="lastInspection">
    SELECT max(iDate) as lastDate 
    FROM inspections
    WHERE idID = #url.dID#;
</cfquery>
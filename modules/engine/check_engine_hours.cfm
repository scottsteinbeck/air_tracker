<cfquery name="engineInfo">
    SELECT *
    FROM engine
    WHERE eID=#url.eID#
</cfquery>
<!--- <cfdump var="#engineInfo#"> --->

<cfset yearlyTotals = deserializeJSON(engineInfo.eYearlyTotals)>

<!--- <cfscript>
    mostRecentYear = yearlyTotals.keyArray().reduce(function(acc, x){
        if(x > acc) acc = x;
        return acc;
    }, 2014);
    currentYear = url.keyExists("year") ? url.year : mostRecentYear;
</cfscript> --->

<cfquery name="engineHours">
    SELECT YEAR(a.ehDate) as yr, DATE_FORMAT(a.ehDate,'%M') as mo, a.ehDate, DATE_FORMAT(a.ehDate, '%D') as day, ifNull(a.ehHoursTotal,0) as ehHoursTotal, a.ehEID,
    greatest(0,ifNull(a.ehHoursTotal,0) - ifNull((
        select ehHoursTotal 
        from engine_hours b
        WHERE b.ehEID=a.ehEID and b.ehDate < a.ehDate 
        order by b.ehDate Desc
        Limit 1
    ),a.ehHoursTotal)) as elapsedTotal
    FROM engine_hours a
    WHERE ehEID=#url.eID# AND
        ehDeleteDate IS NULL
        and ehDate >= (
            select c.ehDate 
            from engine_hours c  
            WHERE c.ehEID=a.ehEID 
            and  c.ehHoursTotal > 0
            order by c.ehDate
            Limit 1
        )
    ORDER BY yr, ehDate
</cfquery> 
<!--- <cfdump var="#engineHours#"> --->

<style>
    @media print { 
        a{
            display: none !important;
        }
    }
</style>

<cfoutput>
<div class="row">
    <div class="col"></div>
    <div class="col-2">
        <a href="index.cfm?action=engine_hours" class="btn btn-outline-primary @media print{}">
            <i class="fas fa-angle-left"></i> Back to Engine Hours
        </a>
        <a href="index.cfm?action=add_engine_hours&dID=#dairyName.dID#&eID=#url.eID#" class="mt-2 btn btn-outline-primary @media print{}">
             Edit Hours
        </a>
        
    </div>
</div>

    <script>
    document.title = "#dairyName.dCompanyName# #engineInfo.eName# Engine Hour Records";
    </script>
    </cfoutput>
<div class="p-3">
    <cfoutput query="engineHours" group="yr">
        <cfset onTheFlyYearlyHours = 0>
        <h3 style="text-align:center">#dairyName.dCompanyName#</h3>
        <h4 style="text-align:center">#engineInfo.eName#</h4>
        <h4 style="text-align:center">Year #yr#</h4>
        <table class="table table-fixed table-striped"  style="page-break-after: always">
            <thead>
                <tr>
                    <th>Month/Day</th>
                    <th>Month Hours</th>
                    <th>Total Hours</th>
                </tr>
            </thead>
            <tbody>
                <cfoutput>
                    <tr>
                        <th>#engineHours.mo# #engineHours.day#</th>
                        <th>#engineHours.elapsedTotal#</th>
                        <th>#engineHours.ehHoursTotal#</th>
                    </tr>
                    <cfset onTheFlyYearlyHours += isNumeric(engineHours.elapsedTotal) ? engineHours.elapsedTotal : 0>
                </cfoutput>
            </tbody>
            <tfoot class="table-dark">
                <tr>
                    <th></th>
                    <th> #NumberFormat(yearlyTotals[yr].service,"9.99")# Hours</th>
                    <th>Power loss hours: #NumberFormat(yearlyTotals[yr].pl,"9.99")#</th>
            </tfoot>
        </table>
    </cfoutput>
</div>

<!--- 2020 101.4+356.4+179.6+311.3+151.7+243.6+193.4+261.6+293.1+298.3+220=2,610.4 --->
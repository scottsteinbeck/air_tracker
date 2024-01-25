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
    SELECT YEAR(a.ehDate) as yr, DATE_FORMAT(a.ehDate,'%M') as mo, a.ehDate, a.ehHoursTotal, a.ehEID,
    a.ehHoursTotal - ifNull((
        select ehHoursTotal 
        from engine_hours b
        WHERE b.ehEID=a.ehEID and b.ehDate < a.ehDate 
        order by b.ehDate Desc
        Limit 1
    ),0) as elapsedTotal
    FROM engine_hours a
    WHERE ehEID=#url.eID# AND
        ehDeleteDate IS NULL
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

<div class="row">
    <div class="col"></div>
    <div class="col-2">
        <a href="index.cfm?action=engine_hours" class="btn btn-outline-primary @media print{}">
            <i class="fas fa-angle-left"></i> Back to Engine Hours
        </a>
    </div>
</div>

<cfoutput>
    <h3 class="text-center">#engineInfo.eName#</h3>
</cfoutput>

<div class="p-3">
    <cfoutput query="engineHours" group="yr">
        <cfset onTheFlyYearlyHours = 0>
        <h3>#yr#</h3>
        <table class="table table-fixed table-striped">
            <thead>
                <tr>
                    <th>Month</th>
                    <th>Month Hours</th>
                    <th>Total Hours</th>
                </tr>
            </thead>
            <tbody>
                <cfoutput>
                    <tr>
                        <th>#engineHours.mo#</th>
                        <th>#engineHours.elapsedTotal#</th>
                        <th>#engineHours.ehHoursTotal#</th>
                    </tr>
                    <cfset onTheFlyYearlyHours += isNumeric(engineHours.elapsedTotal) ? engineHours.elapsedTotal : 0>
                </cfoutput>
            </tbody>
        </table>
        <div class="pb-5" style="font-size: 20px">
            Yearly hours: #yearlyTotals[yr].service# | Power loss hours: #yearlyTotals[yr].pl#
            <!--- <br>
            #onTheFlyYearlyHours# --->
        </div>
    </cfoutput>
</div>

<!--- 2020 101.4+356.4+179.6+311.3+151.7+243.6+193.4+261.6+293.1+298.3+220=2,610.4 --->
<cfquery name="engineInfo">
    SELECT *
    FROM engine
    WHERE eID=#url.eID#
</cfquery>

<cfquery name="engineHours">
    SELECT *
    FROM engine_hours
    WHERE ehEID=#url.eID# AND year(ehDate) = #year(url.eDate)#
    ORDER BY ehDate
</cfquery>

<!--- <cfdump var=#engineHours#> --->

<cfset month_hours = [0,0,0,0,0,0,0,0,0,0,0,0]>
<cfset month_acc_hours = duplicate(month_hours)>
<cfif engineHours.RecordCount gt 0>
    <cfset day_hours  = {}>

    <!--- get avrege hours per day and put them into day_hours --->
    <cfset prev_date = min(createDate(2021,1,1),engineHours.ehDate)>
    <cfset prev_hours = engineHours.ehHoursTotal>

    <cfloop query="engineHours">
        <cfset elapsed_engine_hrs = engineHours.ehHoursTotal - prev_hours>
        <cfset elapsed_days = dateDiff('d', prev_date, engineHours.ehDate)>

        <!--- take the avrage between the time between the two dates of entry and the value of the last entry and put thr resolt into
        the daily_engine_hrs veriable --->
        <cfset daily_engine_hrs = 0>
        <cfif elapsed_days gt 0>
            <cfset daily_engine_hrs = elapsed_engine_hrs/elapsed_days>
        </cfif>

        <!--- set eatch day in day_hours equal to the corisponding daily_engine_hrs value starting at the last entry and ending
        before the most reacent one --->
        <cfloop index="iDate" from="#prev_date#" to="#engineHours.ehDate#" step="#CreateTimeSpan(1,0,0,0)#">
            <cfset day_hours[dateformat(iDate,'yyyy-mm-dd')] = (daily_engine_hrs)>
        </cfloop>

        <!--- set the preves entry date and the preveous entry value fore next iteration --->
        <cfset prev_date = engineHours.ehDate>
        <cfset prev_hours = engineHours.ehHoursTotal>

        <!--- if on the last entry deleat all preveous hours up to the last recorded entry --->
        <cfif engineHours.currentRow is engineHours.recordcount>
            <cfloop index="iDate" from="#prev_date#" to="#createDate(2021, 12, 31)#" step="#CreateTimeSpan(1,0,0,0)#">
                <cfset day_hours[dateformat(iDate,'yyyy-mm-dd')] =  0>
            </cfloop>
        </cfif>
    </cfloop>

    <!--- set eatch month in month_hours to the acumulated hours per day fore that month --->
    <cfloop collection="#day_hours#" item="iDateKey">
        <cfset month_hours[month(iDateKey)] += precisionEvaluate(day_hours[iDateKey])>
    </cfloop>

    <!--- get the total hours per month --->
    <cfset starting_hours = engineHours.ehHoursTotal>

    <cfloop from="1" to="#month_hours.len()#" index="i">
        <cfset month_acc_hours[i] = precisionEvaluate(starting_hours + month_hours[i])>
        <cfset starting_hours = month_acc_hours[i]>
    </cfloop>
</cfif>

<!--- <cfdump var=#month_acc_hours#> --->
<!--- <cfdump var=#month_hours#> --->
<!--- <cfdump var=#day_hours#> --->

<!--- <cfset hours[12][31] = 0>
<cfset preEHoursTotal = engineHours.eHoursTotal[1]>
<cfoutput query="engineHours">
    <cfset hours[month(engineHours.eDate)][day(engineHours.eDate)]=engineHours.eHoursTotal - preEHoursTotal>
    <cfset hours[month(engineHours.eDate)][day(engineHours.eDate)]=1>
    <cfset preEHoursTotal = engineHours.eHoursTotal>
</cfoutput>--->
<!--- <cfdump var=#arraySum(hoursDsp[1])/eDays#> --->

<div class="row justify-content-md-center">
    <div class="col-lg-3 col-md-5 col-sm-12 mb-3" >
        <div class="card">
            <div class = "card-body">
                <cfoutput>
                    <form action="index.cfm?action=add_engine_hours">
                        <input type="hidden" name="action" value="add_engine_hours">
                        <input type="hidden" name="eID" value="#url.eID#"/>
                        <!--- <input type="date" value="#url.eDate#" name="eDate"/> --->
                        <div class="row mb-3 margin-left">
                            <div class="col-sm-7">
                                <lable class="visually-hidden" for="year_picker">
                                <select name="eDate" class="form-select" id="year_picker" onchange="form.submit()">
                                    <cfloop from="2014" to=#year(now())# index="YR">
                                        <option value="#LSDateFormat(createDate(YR,1,1),"yyyy-mm-dd")#" <cfif YR eq year(url.eDate)>selected="selected"</cfif>>#YR#</option>
                                    </cfloop>
                                </select>
                            </div>
                        </div>
                    </form>
                    <form action="index.cfm">
                        <input type=hidden name="action" value="save_engine_hours">
                        <input type=hidden name="eID" value="#url.eID#">

                        <div class="row mb-3">
                        <lable for="set_hrs_at" class="col-sm-4 col-form-label">Recored on</lable>
                            <div class="col-sm-7">
                                <input type=date name="eDate" max="#dateformat(year(url.eDate)&"-12-31","yyyy-mm-dd")#" min="#dateformat(year(url.eDate)&"-1-1","yyyy-mm-dd")#" id="set_hrs_at" class="form-control" value="#url.eDate#">
                            </div>
                        </div>

                        <div class="row mb-3">
                            <lable for="hrs_amount" class="col-sm-4 col-form-label">Hours</lable>
                            <div class="col-sm-7">
                                <input id="hrs_amount" class="form-control" name="ehHoursTotal" pattern="^\d*(\.\d{0,3})?$" autofocus="autofocus"/>
                            </div>
                        </div>

                        <div class="col-12">
                            <input type="submit" class="btn btn-block btn-outline-primary" value="Enter"/>
                        </div>
                    </form>
					<a href="index.cfm?action=engine_hours" class="col-3 mt-3 btn btn-block btn-outline-primary">Done</a>
                </cfoutput>
                <!--- <cfdump var=#engineHours#> --->
            </div>
        </div>
    </div>

    <div class="col-lg-3 col-md-5 col-sm-12 mb-3">
        <div class="card">
            <div class = "card-body">
                <cfoutput>
                    <div class="table">
                        <table>
                            <thead>
                                <tr>
                                    <th>
                                        Month
                                    </th>
                                    <th>
                                        Monthly total
                                    </th>
                                    <th>
                                        Running total
                                    </th>
                                </tr>
                            </thead>
                            <tbody>
                                <cfloop from="1" to="12" index="month">
                                    <tr>
                                        <td>#monthAsString(month)#</td>
                                        <cfif engineHours.RecordCount gt 0>
                                            <td>#round(month_hours[month],3)#</td>
                                            <td>#round(month_acc_hours[month],3)#</td>
                                            <cfelse>
                                            <cfloop from="1" to="2" index="i"><td>---</td></cfloop>
                                        </cfif>
                                    </tr>
                                </cfloop>
                            </tbody>
                        </table>
                    </div>
                </cfoutput>
            </div>
        </div>
    </div>
</div>
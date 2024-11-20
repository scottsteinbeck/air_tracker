<cfsetting requesttimeout="999999999">
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>test</title>
    <script src="https://cdn.jsdelivr.net/npm/vue@2.6.12/dist/vue.js"></script>
</head>
<body>
    <cfspreadsheet action="read" src="#expandPath('/engineHoursImport.xlsx')#" query="excelFile"/>
    
    <cfset Index=1>
    <cfloop query="excelFile">
        <cfset Index++>
        <cfoutput>
            #addEngineHour(excelFile.COL_3[Index],excelFile.COL_5[1],excelFile.COL_4[Index],excelFile.COL_5[Index],excelFile.COL_6[Index])#<br/>
            #addEngineHour(excelFile.COL_3[Index],excelFile.COL_7[1],excelFile.COL_4[Index],excelFile.COL_7[Index],excelFile.COL_8[Index])#<br/>
            #addEngineHour(excelFile.COL_3[Index],excelFile.COL_9[1],excelFile.COL_4[Index],excelFile.COL_9[Index],excelFile.COL_10[Index])#<br/>
            #addEngineHour(excelFile.COL_3[Index],excelFile.COL_11[1],excelFile.COL_4[Index],excelFile.COL_11[Index],excelFile.COL_12[Index])#<br/>
            #addEngineHour(excelFile.COL_3[Index],excelFile.COL_13[1],excelFile.COL_4[Index],excelFile.COL_13[Index],excelFile.COL_14[Index])#<br/>
            #addEngineHour(excelFile.COL_3[Index],excelFile.COL_15[1],excelFile.COL_4[Index],excelFile.COL_15[Index],excelFile.COL_16[Index])#<br/>
        </cfoutput>
        <br/>
    </cfloop>

    <cfdump var=#excelFile#>

    <input step="10" type="number" max="100" min="0" name="randomNumber" value="0" />
    <input type="number" id="tentacles" name="tentacles" min="10" max="100">
    <div id="testButton">
    <p v-if="exists">Hello</p>
    <button @click="toggleMessage()">Don't click me</button>
    <ul>
        <li v-for="n in arrayOfNumbers" v-if="exists">
            {{n}}
        </li>
    </ul>
    <ul>
        <li v-for="desserts in dessert" :key="desserts.good">
            {{desserts.good}}
        </li>
    </ul>
</div>

<script>
    new Vue({
        el: '#testButton',
        data: {
            exists: true,
            arrayOfNumbers: [3,5,1,8,9,25,64],
            dessert: [{best: "iceCream"},{good: "cookes"},{good: "browines"},{good: "chocolateBar"}]
        },
        methods:{
            toggleMessage:function(){
                return this.exists=!this.exists;
            },

            scrollFunction:function(){
                console.log("scrolled");
            }
        },
    });
</script>

<cfscript>
    function addEngineHour(eID,YR,MO,HRS,notes)
    {
        if (isnumeric(HRS))
        {
            var ehDate = dateformat(CreateDate(YR,MO,"1"),"yyyy-mm-dd");
            
            // queryExecute(
            //     "
            //         INSERT INTO engine_hours(ehEID,ehDate,ehHoursTotal,ehNotes)
            //         VALUES (
            //             :ehID,
            //             :ehDate,
            //             :HRS,
            //             :notes
            //         )
            //     ",
            //     {
            //         ehID={value=eID, cfsqltype="cf_sql_integer"}, 
            //         ehDate={value=ehDate, cfsqltype="cf_sql_date"},
            //         HRS={value=HRS, cfsqltype="cf_sql_double"},
            //         notes={value=notes, cfsqltype="cf_sql_varchar"}
            //     }
            // );
            return "#eID#,#ehDate#,#HRS#,#notes#";
        }
        return "invaled data";
    }
</cfscript>
</body>
</html>
<!--- <cfquery name = "questionsList">
    SELECT *
    FROM questions
    order by qPriority;
</cfquery>

<cfoutput query="questionsList">
    #questionsList.qID#
</cfoutput> --->

<!--- <cfset incrementV = 1>
<cfoutput query = "questionsList">
    <cfquery name = "setQPriority">
        UPDATE questions
        SET qPriority = #incrementV#
        WHERE qID = #qID#;
    </cfquery>
    <cfset incrementV++>
</cfoutput> --->

<!--- <cfset incrementV = 0>
<cfoutput query = "questionsList">
    <cfif questionsList.qType is "Heading"><cfset incrementV++></cfif>
    <cfquery name = "setQPriority">
        UPDATE questions
        SET qPriority = #incrementV#
        WHERE qID = #qID#;
    </cfquery>
</cfoutput> --->
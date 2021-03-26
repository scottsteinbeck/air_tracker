<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>test</title>
    <script src="https://cdn.jsdelivr.net/npm/vue@2.6.12/dist/vue.js"></script>
</head>
<body>
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
    </ui>

    
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
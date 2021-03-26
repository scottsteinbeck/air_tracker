<script src="https://ajax.googleapis.com/ajax/libs/jquery/3.5.1/jquery.min.js"></script>
<script src="numeral.min.js"></script>
<cfparam name="url.dID" default="0">
<cfparam name="url.year" default="#year(now())#">
<cfparam name="url.Month" default="#month(now())#">

<cfquery name="DairyList">
    select * from dairies
</cfquery>
<cfquery name="typelist" returntype="array">
    select * 
    from cow_types    
    left join cow_numbers on cow_types.tID=cow_numbers.cnTID and cndID=#url.dID#
</cfquery>

<form action="index.cfm" method="GET">
    <input type="hidden" name="action" value="cow_numbers">
    <select name="dID" id="" onchange="form.submit()">
        <option value="0"> none</option>
        <cfoutput query="DairyList" >
            <option value="#dID#" <cfif url.dID eq dID>selected ="selected"</cfif> >#dCompanyName#</option>
        </cfoutput>
    </select>

    <select name="year" id="" onchange="form.submit()"> 
        <cfoutput><cfloop from="2014" to="#year(now())#" index="YR">
        <option value="#YR#" <cfif url.year eq YR>selected ="selected"</cfif> >#YR#</option>
        </cfloop>
        </cfoutput>
    </select>  
</form>

<form action="index.cfm?action=act_save_numbers" method="POST">
<input type="hidden" name="dID" value="<cfoutput>#url.dID#</cfoutput>">
<input type="hidden" name="year" value="<cfoutput>#url.year#</cfoutput>">
<div id='mainVue'>
    <table id="cownumbers" class="table table-bordered">
        <thead>
            <tr>
                <th>Type</th>
                <th>Permitted</th>
                <th>Qtr1</th>
                <th>Qtr2</th>
                <th>Qtr3</th>
                <th>Qtr4</th>
            </tr>
        </thead>
        <tbody>
            <tr v-for="row in typeList">
                <td>
                    {{row.Name}}
                </td>
                <td v-for="column in columns">
                    <input type="number" v-model="row[column]" :readonly="column=='cnPermitted'" />
                </td>
            </tr>
            <tr>
                <td>
                    {{totalRow.Name}}
                </td>
                <td v-for="column in columns" class="text-center">
                    {{totalRow[column]}}
                </td>
            </tr>
            <tr>
                <td>
                    {{supportStockRow.Name}}
                </td>
                <td v-for="column in columns" class="text-center">
                    {{supportStockRow[column]}}
                </td>
            </tr>
        </tbody>
    </table>
</div>


    <input type="submit" value="Save Questions" class = "btn btn-outline-primary margin-left">
</form> 


<script>
//vue version
var typeList = <cfoutput>#serializeJSON(typelist)#</cfoutput>;

cowNumbers = new Vue({
    el: '#mainVue',
    computed: {
        totalRow: function () {
            var _self = this;
            var totals = { Name:"Totals", cnPermitted:0, CnQtr1:0, CnQtr2:0, CnQtr3:0, CnQtr4:0};
            for(var i = 0; i < _self.typeList.length; i++){
                var row = _self.typeList[i];
                for(var t = 0; t < _self.columns.length; t++){
                    var colName = _self.columns[t];
                    totals[colName] += parseFloat(row[colName]);
                }
            }
            return totals;
        },

        supportStockRow: function () {
            var _self = this;
            var totals = { Name:"Support Stock Totals", cnPermitted:0, CnQtr1:0, CnQtr2:0, CnQtr3:0, CnQtr4:0};
            for(var i = 0; i < _self.typeList.length; i++){
                var row = _self.typeList[i];
                if(row.Type != "Support"){ continue; }
                for(var t = 0; t < _self.columns.length; t++){
                    var colName = _self.columns[t];
                    totals[colName] += parseFloat(row[colName]);
                }
            }
            return totals;
        }
    },
    data: {
        typeList: typeList,
        columns: ["cnPermitted","CnQtr1","CnQtr2","CnQtr3","CnQtr4"]
    },
    
    methods: {
        
    },
});
</script>

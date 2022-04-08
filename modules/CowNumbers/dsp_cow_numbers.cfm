<script src="https://ajax.googleapis.com/ajax/libs/jquery/3.5.1/jquery.min.js"></script>
<cfparam name="url.dID" default="0">
<cfparam name="url.year" default="#year(now())#">
<cfparam name="url.Month" default="#month(now())#">

<cfquery name="DairyList">
    SELECT * FROM dairies
</cfquery>

<cfquery name="cownumbers">
    SELECT *
    FROM cow_numbers 
    WHERE cndID=#url.dID# AND cnTID = 1 AND CnYear != #url.year#
</cfquery>

<cfif url.keyExists("replaceFromYear")>

    <cfquery>
        DELETE
        FROM cow_numbers
        WHERE cndID=#url.dID# AND cnYear = #url.year#
    </cfquery>

    <cfquery name="importYear">
        INSERT INTO cow_numbers( cnTID, cnPermitted, CnQtr1, CnQtr2, CnQtr3, CnQtr4, CndID, CnYear)
        SELECT cnTID, cnPermitted, CnQtr1, CnQtr2, CnQtr3, CnQtr4, CndID, #url.year#
        FROM cow_numbers
        WHERE cndID=#url.dID# AND cnYear = #url.replaceFromYear#
    </cfquery>

</cfif>

<cfquery name="typelist" returntype="array">
    SELECT *
    FROM cow_types
    LEFT JOIN cow_numbers ON cow_types.tID=cow_numbers.cnTID AND cndID=#url.dID# AND cnYear = #url.year#
</cfquery>

<div id='mainVue'>

    <form action="index.cfm" method="GET">
        <div class="row m-2">
            <div class="col-lg-3 col-6">
                <input type="hidden" name="action" value="cow_numbers">
                <select name="dID" id="" onchange="form.submit()" class="form-control">
                    <option value="0"> none</option>
                    <cfoutput query="DairyList" >
                        <option value="#dID#" <cfif url.dID eq dID>selected ="selected"</cfif> >#dCompanyName#</option>
                    </cfoutput>
                </select>
            </div>
            <div class="col-lg-2 col-4">
                <select name="year" id="" onchange="form.submit()" class="form-control">
                    <cfoutput><cfloop from="2014" to="#year(now())#" index="YR">
                    <option value="#YR#" <cfif url.year eq YR>selected ="selected"</cfif> >#YR#</option>
                    </cfloop>
                    </cfoutput>
                </select>
            </div>
        </div>
    </form>

    <form action="index.cfm?action=act_save_numbers" method="POST" id="cowNums">
        <input type="hidden" name="dID" value="<cfoutput>#url.dID#</cfoutput>">
        <input type="hidden" name="year" value="<cfoutput>#url.year#</cfoutput>">
        <div id="no-more-tables">
            <table id="cownumbers" class="table table-bordered table-striped">
                <thead>
                    <tr>
                        <th>Type</th>
                        <th>Permitted
							<cfif session.USer_TYPEID eq 1>
								<button type="button" @click="lockUnlock('permitted')" class="btn btn-outline-primary margin-left mb-1">
									<i v-if="canEdit.permitted" class="fas fa-lock-open"></i>
									<i v-if="!canEdit.permitted" class="fas fa-lock"></i>
								</button>
							</cfif>
						</th>
                        <th>Qtr1
							<cfif session.USer_TYPEID eq 1>
								<button type="button" @click="lockUnlock('qtr1')" class="btn btn-outline-primary margin-left mb-1">
									<i v-if="canEdit.qtr1" class="fas fa-lock-open"></i>
									<i v-if="!canEdit.qtr1" class="fas fa-lock"></i>
								</button>
							</cfif>
						</th>
                        <th>Qtr2
							<cfif session.USer_TYPEID eq 1>
								<button type="button" @click="lockUnlock('qtr2')" class="btn btn-outline-primary margin-left mb-1">
									<i v-if="canEdit.qtr2" class="fas fa-lock-open"></i>
									<i v-if="!canEdit.qtr2" class="fas fa-lock"></i>
								</button>
							</cfif>
						</th>
                        <th>Qtr3
							<cfif session.USer_TYPEID eq 1>
								<button type="button" @click="lockUnlock('qtr3')" class="btn btn-outline-primary margin-left mb-1">
									<i v-if="canEdit.qtr3" class="fas fa-lock-open"></i>
									<i v-if="!canEdit.qtr3" class="fas fa-lock"></i>
								</button>
							</cfif>
						</th>
                        <th>Qtr4
							<cfif session.USer_TYPEID eq 1>
								<button type="button" @click="lockUnlock('qtr4')" class="btn btn-outline-primary margin-left mb-1">
									<i v-if="canEdit.qtr4" class="fas fa-lock-open"></i>
									<i v-if="!canEdit.qtr4" class="fas fa-lock"></i>
								</button>
							</cfif>
						</th>
                    </tr>
                </thead>
                <tbody>
                    <tr class="d-md-none">
                        <td data-title="Title">
                            {{totalRow.Name}}
                        </td>
                        <td v-for="column in columns" class="text-center" :data-title="tableHeaders[column]">
                            {{totalRow[column]}}
                        </td>
                    </tr>
                    <tr class="d-md-none">
                        <td data-title="Title">
                            {{supportStockRow.Name}}
                        </td>
                        <td v-for="column in columns" class="text-center" :data-title="tableHeaders[column]">
                            {{supportStockRow[column]}}
                        </td>
                    </tr>

					<!---
						I used v-for="n in [0,1,2,3,4,6,5]" insted of v-for="row in typeList" because
						of the way the rows needed to be ordered and because rows needed to be added that wheren't
						in the typeList array
					--->
					<template v-for="n in [0,1,2,3,4,6,5]">
						<!---
							The calves row needs to go between the support stock totals row and the totals row
							at the botten of the table
						--->
						<tr class="only-desktop" v-if="n == 5">
							<td>
								{{supportStockRow.Name}}
							</td>
							<td v-for="column in columns" class="text-center">
								{{supportStockRow[column] | formatNumber}}
							</td>
						</tr>

						<tr>
							<td>
								{{typeList[n].Name}}
							</td>
							<td v-for="column in columns">
								<cfif session.USer_TYPEID eq 1>
									<!--- the inputs are named in a way that they can be easly red in the query by knowing the tID --->
									<!--- canEdit is a struct that stores true or false values for Permitted Qtr1 Qtr2 ect that gove us the locked or unlokced state of the text box --->
									<!--- the typeList values that are in each text box are models so the total rows will update when they are changed --->
									<input type="number" :name="'dn_'+typeList[n].TiD+'_Permitted'" v-model="typeList[n][column]" v-if="column == 'cnPermitted'" :readonly="!canEdit.permitted" onclick="$(this).select()"/>
									<input type="number" :name="'dn_'+typeList[n].TiD+'_Qtr1'" v-model="typeList[n][column]" v-if="column == 'CnQtr1'" :readonly="!canEdit.qtr1" onclick="$(this).select()"/>
									<input type="number" :name="'dn_'+typeList[n].TiD+'_Qtr2'" v-model="typeList[n][column]" v-if="column == 'CnQtr2'" :readonly="!canEdit.qtr2" onclick="$(this).select()"/>
									<input type="number" :name="'dn_'+typeList[n].TiD+'_Qtr3'" v-model="typeList[n][column]" v-if="column == 'CnQtr3'" :readonly="!canEdit.qtr3" onclick="$(this).select()"/>
									<input type="number" :name="'dn_'+typeList[n].TiD+'_Qtr4'" v-model="typeList[n][column]" v-if="column == 'CnQtr4'" :readonly="!canEdit.qtr4" onclick="$(this).select()"/>
								<cfelse>
									<!--- only show the text with no text box if the user is not an admin --->
									<div class="text-center">
										{{typeList[n][column]}}
									</div>
								</cfif>
							</td>
						</tr>

						<tr class="only-desktop" v-if="n == 5">
							<td>
								{{totalRow.Name}}
							</td>
							<td v-for="column in columns" class="text-center">
								{{totalRow[column] | formatNumber}}
							</td>
						</tr>

						<!--- the if n == 1 causes mature animals row to be the second row down --->
						<tr v-if="n == 1">
							<td>
								{{matureAnimalsRow.Name}}
							</td>
							<td v-for="column in columns" class="text-center">
								{{matureAnimalsRow[column] | formatNumber}}
							</td>
						</tr>
					</template>
                </tbody>
            </table>
        </div>
		<cfif session.USer_TYPEID eq 1> <input type="submit" value="Save Questions" class = "btn btn-outline-primary margin-left mb-3"> </cfif>
	</form>
    
    <cfif session.USer_TYPEID eq 1>
        <div class="d-flex justify-content-end mr-2 ml-auto">
            <form method="GET" action="/index.cfm" class="form-inline" id="replaceYearForm">
                <label>Replace the data from this year with data from another year. &nbsp;</label>
                
                <cfoutput>
                    <input type="hidden" name="action" value="cow_numbers">
                    <input type="hidden" name="dID" value="#url.dID#">
                    <input type="hidden" name="year" value="#url.year#">
                </cfoutput>
                <select name="replaceFromYear" class="form-control">
                    <cfoutput query="cownumbers">
                        <option value="#dateFormat(cownumbers.CnYear,"YYYY")#">Year #dateFormat(cownumbers.CnYear,"YYYY")#, Milk Qtr1 #cownumbers.CnQtr1#</option>
                    </cfoutput>
                </select>
                <input type="button" @click="replaceFromOtherYear()" value="Replace data" class="btn btn-outline-primary margin-left">
            </form>
        </div>
    </cfif>

</div>


<script>
//vue version
var typeList = <cfoutput>#serializeJSON(typelist)#</cfoutput>;

Vue.filter("formatNumber", function (value) {
    return Number(value).toLocaleString()
});

cowNumbers = new Vue({
    el: '#mainVue',
    computed: {
		// the mature animals row is the milk and dry in each column to be added
		// this function adds the minl and dry for each column and returns the resolt
		matureAnimalsRow: function(){
			var _self = this;
			var totals = { Name:"Mature Animals", cnPermitted:0, CnQtr1:0, CnQtr2:0, CnQtr3:0, CnQtr4:0 };
            for(var i=0; i < _self.typeList.length; i++) {
				var row = _self.typeList[i];
				// since milk and dry are both of the mature type in row we are skipping everything that
				// is not of the mature type
				if(row.Type != "Mature"){ continue; }
				for(var t=0; t < _self.columns.length; t++) {
					// the column variable is a struct that contains string names for each column in the table
					var colName = _self.columns[t];
					if(row[colName] != ""){ totals[colName] += parseFloat(row[colName]); }
					else{ totals[colName] += 0; }
				}
			}
			return totals;
		},

        totalRow: function () {
            var _self = this;
            var totals = { Name:"Totals", cnPermitted:0, CnQtr1:0, CnQtr2:0, CnQtr3:0, CnQtr4:0};
            for(var i = 0; i < _self.typeList.length; i++){
                var row = _self.typeList[i];
                for(var t = 0; t < _self.columns.length; t++){
                    var colName = _self.columns[t];
                    if(row[colName] != ""){ totals[colName] += parseFloat(row[colName]); }
					else{ totals[colName] += 0; }
                }
            }
            return totals;
        },

        supportStockRow: function () {
            var _self = this;
            var totals = { Name:"Support Stock Totals", cnPermitted:0, CnQtr1:0, CnQtr2:0, CnQtr3:0, CnQtr4:0};
            for(var i = 0; i < _self.typeList.length; i++){
                var row = _self.typeList[i];
                if(row.Type != "Support" || row.Name == "Calves"){ continue; }
                for(var t = 0; t < _self.columns.length; t++){
                    var colName = _self.columns[t];
                    if(row[colName] != ""){ totals[colName] += parseFloat(row[colName]); }
					else { totals[colName] += 0; }
                }
            }
            return totals;
        }
    },
    data: {
        typeList: typeList,
        columns: ["cnPermitted","CnQtr1","CnQtr2","CnQtr3","CnQtr4"],
        tableHeaders: {cnPermitted:"Permitted",CnQtr1:"Qtr1",CnQtr2:"Qtr2",CnQtr3:"Qtr3",CnQtr4:"Qtr4"},
		canEdit: {permitted: false, qtr1: false, qtr2: false, qtr3: false, qtr4: false},
    },

    methods: {
		lockUnlock: function(columnName)
		{
            var _self = this;
			if(_self.canEdit[columnName] == true){
				_self.canEdit[columnName] = false;

                var cowNumsForm = document.getElementById("cowNums");
                cowNumsForm.submit();
			}
			else if(columnName != "permitted"){
				_self.canEdit[columnName] = true;
			}
            else
            {
                if(confirm("Are you shure you want to unlock the Permitted input boxes?"))
				{ this.canEdit.permitted = true; }
            }
		},

        replaceFromOtherYear: function()
        {
            if(confirm('Do you want to replace the data from this year with the data from another year?')) 
            { document.getElementById("replaceYearForm").submit(); }
        },
    },
});
</script>

<style>
    @media only screen and (max-width: 768px) {

        /* Force table to not be like tables anymore */
        #no-more-tables table,
        #no-more-tables thead,
        #no-more-tables tbody,
        #no-more-tables th,
        #no-more-tables td,
        #no-more-tables tr {
            display: block;
        }

        /* Hide table headers (but not display: none;, for accessibility) */
        #no-more-tables thead tr {
            position: absolute;
            top: -9999px;
            left: -9999px;
        }

        #no-more-tables tr { border: 1px solid #ccc; }

        #no-more-tables td {
            /* Behave  like a "row" */
            border: none;
            border-bottom: 1px solid #eee;
            position: relative;
            padding-left: 50%;
            white-space: normal;
            text-align:left;
        }

        #no-more-tables td:before {
            /* Now like a table header */
            position: absolute;
            /* Top/left values mimic padding */
            top: 6px;
            left: 6px;
            width: 45%;
            padding-right: 10px;
            white-space: nowrap;
            text-align:left;
            font-weight: bold;
        }

        /*
        Label the data
        */
        #no-more-tables td:before { content: attr(data-title); }

        #no-more-tables tr.only-desktop{display: none}
    }
</style>

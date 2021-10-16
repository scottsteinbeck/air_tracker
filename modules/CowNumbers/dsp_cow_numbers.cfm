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

<form action="index.cfm?action=act_save_numbers" method="POST">
    <input type="hidden" name="dID" value="<cfoutput>#url.dID#</cfoutput>">
    <input type="hidden" name="year" value="<cfoutput>#url.year#</cfoutput>">
        <div id="no-more-tables">
            <table id="cownumbers" class="table table-bordered table-striped">
                <thead>
                    <tr>
                        <th>Type</th>
                        <th>Permitted
							<cfif session.USer_TYPEID eq 1>
								<button type="button" @click="unlockPermitted" class="btn btn-outline-primary margin-left mb-1">
									<i v-if="canEdit.permitted" class="fas fa-lock-open"></i>
									<i v-if="!canEdit.permitted" class="fas fa-lock"></i>
								</button>
							</cfif>
						</th>
                        <th>Qtr1
							<cfif session.USer_TYPEID eq 1>
								<button type="button" @click="canEdit.qtr1 = !canEdit.qtr1" class="btn btn-outline-primary margin-left mb-1">
									<i v-if="canEdit.qtr1" class="fas fa-lock-open"></i>
									<i v-if="!canEdit.qtr1" class="fas fa-lock"></i>
								</button>
							</cfif>
						</th>
                        <th>Qtr2
							<cfif session.USer_TYPEID eq 1>
								<button type="button" @click="canEdit.qtr2 = !canEdit.qtr2" class="btn btn-outline-primary margin-left mb-1">
									<i v-if="canEdit.qtr2" class="fas fa-lock-open"></i>
									<i v-if="!canEdit.qtr2" class="fas fa-lock"></i>
								</button>
							</cfif>
						</th>
                        <th>Qtr3
							<cfif session.USer_TYPEID eq 1>
								<button type="button" @click="canEdit.qtr3 = !canEdit.qtr3" class="btn btn-outline-primary margin-left mb-1">
									<i v-if="canEdit.qtr3" class="fas fa-lock-open"></i>
									<i v-if="!canEdit.qtr3" class="fas fa-lock"></i>
								</button>
							</cfif>
						</th>
                        <th>Qtr4
							<cfif session.USer_TYPEID eq 1>
								<button type="button" @click="canEdit.qtr4 = !canEdit.qtr4" class="btn btn-outline-primary margin-left mb-1">
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

                    <tr v-for="row in typeList">
                        <td data-title="Type">
                            {{row.Name}}
                        </td>
                        <td v-for="column in columns" :data-title="tableHeaders[column]">
                            <cfif session.USer_TYPEID eq 1>
                                <input type="number" :name="'dn_'+row.TiD+'_Permitted'" v-model="row[column]" v-if="column == 'cnPermitted'" :readonly="!canEdit.permitted"/>
                                <input type="number" :name="'dn_'+row.TiD+'_Qtr1'" v-model="row[column]" v-if="column == 'CnQtr1'" :readonly="!canEdit.qtr1"/>
                                <input type="number" :name="'dn_'+row.TiD+'_Qtr2'" v-model="row[column]" v-if="column == 'CnQtr2'" :readonly="!canEdit.qtr2"/>
                                <input type="number" :name="'dn_'+row.TiD+'_Qtr3'" v-model="row[column]" v-if="column == 'CnQtr3'" :readonly="!canEdit.qtr3"/>
                                <input type="number" :name="'dn_'+row.TiD+'_Qtr4'" v-model="row[column]" v-if="column == 'CnQtr4'" :readonly="!canEdit.qtr4"/>
                            <cfelse>
                                <div class="text-center">
                                    {{row[column]}}
                                </div>
                            </cfif>
                        </td>
                    </tr>

                    <tr class="only-desktop">
                        <td>
                            {{totalRow.Name}}
                        </td>
                        <td v-for="column in columns" class="text-center">
                            {{totalRow[column]}}
                        </td>
                    </tr>
                    <tr class="only-desktop">
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
		<cfif session.USer_TYPEID eq 1> <input type="submit" value="Save Questions" class = "btn btn-outline-primary margin-left"> </cfif>
	</form>
</div>


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
                if(row.Type != "Support"){ continue; }
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
		canEdit: {permitted: false, qtr1: false, qtr2: false, qtr3: false, qtr4: false}
    },

    methods: {
		unlockPermitted: function()
		{
			if(this.canEdit.permitted == true){
				this.canEdit.permitted = false;
			}
			else{
				if(confirm("Are you shure you want to unlock the Permitted input boxes?"))
				{ this.canEdit.permitted = true; }
			}
		}
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

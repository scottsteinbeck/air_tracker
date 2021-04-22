    <cfparam name="url.qID" default="0">

    <cfquery name="questionList">
        SELECT questions.*, question_months.mID
        FROM questions
        LEFT JOIN question_months ON question_months.qID=questions.qID
        ORDER BY qPriority , qID
    </cfquery>
    <cfset qList = []>
    <cfoutput query="questionList" group="qID">
        <cfset temp = {
            'qID': qID,
            'qTitle': qTitle,
            'qType': qType,
            'qDescription': qDescription,
            'qPriority': qPriority,
            'qFreq': qFreq,
            'qNumber': qNumber,
            'months': []
        }>
        <cfoutput>
            <cfif isNumeric(mID)>
                <cfset arrayAppend(temp.months,mID)>
            </cfif>
        </cfoutput>
        <cfset arrayAppend(qList,temp)>
    </cfoutput>

    <cfquery name="activeQuestion" dbtype="query">
        select *
        from questionList
        where qID = #url.qID#
    </cfquery>

    <cfquery name="monthList">
        select * 
        from month_names
        left join question_months on question_months.mID=month_names.mID
    </cfquery>

<style>
    .fa-6{
        font-size: 2em;
    }
</style>

    <!--- Form to get the question id that we're setting the months for --->
<div id="questionContainer">
    <div class="container-fluid">
        <div class="row m-2 p-2 border">
            <!--- Page tital and forward and backward arows --->
            <cfoutput>
                <button class="col-1 btn btn-secondary" :class="(left_button_enabled) ? '' : 'disabled'" name="prevousButton" @click="leftArrowClick()"><i class="fa fa-6 fa-angle-double-left"></i></button>
                <h4 class="col text-center text-truncate">
                    {{active.qTitle}}
                </h4>
                <button class="col-1 btn btn-secondary" :class="(right_button_enabled) ? '' : 'disabled'" name="prevousButton" @click="rightArrowClick()"><i class="fa fa-6 fa-angle-double-right"></i></button>
            </cfoutput>
        </div>
        
        <div class="row m-2">
            <div class="col-sm-9" id="checklistContainer" style="height:600px; overflow:auto">
                <!--- Selector with scroll bar --->
                <ul>
                    <li v-for="(item,idx) in qList" :key="item.qID" class="list-group-item" :class="(item.qID == active.qID)?'active':''">
                        <div v-if="item.qType == 'Heading'"><h4>{{item.qTitle}}</h4></div>
                        <div v-else>
                            <button class="btn btn-sm btn-primary" @click="selectClick(item)" :class="[(item.qID == active.qID)?'disabled':'']"><i class="fa fa-6 fa-plus-circle"></i></button>
                            {{item.qNumber}} {{item.qTitle}}
                            <br/><small v-for="(id,idx) in item.months">
                                {{months_names[id]}}<span v-if="idx < item.months.length-1">,</span>
                            </small>
                        </div>
                    </li>
                </ul>
            </div>

        <div class="col-sm-3">
            <div class = "card sticky-top ">
                <div class = "card-body">
                    <!--- Form to send to database of months  --->
                    <table>
                        <thead>
                            <tr>
                                <th>Month Required</th>
                            </tr>
                        </thead>
                        <tbody>
                            <div v-for="(item,id) in months_names">
                                <input type="checkbox" name="months" v-model="active.months" :value="id">
                                <label>{{item}}</label>
                            </div>
                        </tbody>
                    </table>
                    <button @click="saveCheckedMonths()" class="btn btn-outline-primary">Save Questions</button>
                </div>
            </div>
        </div>
    </div>
</div>
</div>
<script>
    var qList = <cfoutput>#serializeJSON(qList)#</cfoutput>;
    questionMonths = new Vue({
        el: '#questionContainer',
        data:{
            activeIndex: 0,
            qList:qList,
            active: this.qList[0],
            months_names: [ "All", "January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December" ],
        },
        mounted: function(){
            this.active =  this.questionsOnly[this.activeIndex];
        },
        computed:{
            questionsOnly: function(){
                return this.qList.filter(function(x){
                    return x.qType != 'Heading'; 
                })
            },
            right_button_enabled: function(){return (this.activeIndex + 2 <= this.questionsOnly.length)},
            left_button_enabled: function(){return (this.activeIndex - 1 >= 0)}
        },
        methods:{
            saveCheckedMonths: function(){
                console.log(this.active);
                $.ajax({
                    method: "POST",
                    url: "/ajax/questions/act_save_months.cfm",
                    data: { 
                        qID: this.active.qID, 
                        months: this.active.months.join(",")
                    }
                })
                .done(function( res ) {
                    alert( "Data Saved: " + res.success );
                });
            },
            rightArrowClick: function(){
                var nexIdx = this.activeIndex+1;
                this.activeIndex = (nexIdx < this.questionsOnly.length) ? nexIdx : this.activeIndex;
                this.active = this.questionsOnly[this.activeIndex];
                this.showActiveItem();
            },
            leftArrowClick: function(){
                var prevIdx = this.activeIndex-1;
                this.activeIndex = (prevIdx >= 0) ? prevIdx : this.activeIndex;
                this.active = this.questionsOnly[this.activeIndex];
                this.showActiveItem();
            },
            selectClick: function(item){
                this.active = item;
                console.log(this.qList.indexOf(item))
                this.activeIndex = this.questionsOnly.indexOf(item);
            },
            showActiveItem: function(){
                var $parentDiv = $('#checklistContainer');
                var $innerListItem = $('.list-group-item.active');
                $parentDiv.scrollTop(
                    $parentDiv.scrollTop() + 
                    $innerListItem.position().top
                    - $parentDiv.height()/2 
                    + $innerListItem.height()/2
                );
            }
        }
    });


</script>
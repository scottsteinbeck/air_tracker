
    <!DOCTYPE html>
    <html>
        <head>
            <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.0.0-beta2/dist/css/bootstrap.min.css" rel="stylesheet" integrity="sha384-BmbxuPwQa2lc/FVzBcNJ7UAyJxM6wuqIj61tLrc4wSX0szH/Ev+nYRRuWlolflfl" crossorigin="anonymous">
            <style>
            /*
                .centered
                {
                    position: fixed;
                    top: 25%;
                    left: 43%;
                }

                .container
                {
                    background-color: #f2f2f2;
                    padding: 50px;
                    border-radius: 4px;
                    width: 15%;
                }

                label{
                    display: block;
                }
                input{
                    display: block;
                }

                input[type=submit]
                {
                    font: 14px Arial;
                    border: none;
                    background-color: rgb(28, 214, 77);
                    color: white;
                    padding: 11px 32px;
                    width: 100%
                    border: 2px solid red;
                    border-radius: 4px;
                    cursor: pointer;
                }

                .cancelButton {
                    font: 14px Arial;
                    text-decoration: none;
                    background-color: #d53434;
                    color: #333333;
                    padding: 11px 32px;
                    border-radius: 4px;
                }

                input[type=text]
                {
                    width: 100%;
                    padding: 5px 5px;
                }*/
                .btn-outline-primary {
                    color: #fff;
                    background-color: #0082d8;
                    border-color: #000000;
                }
                .btn-outline-primary:hover {
                    color: #fff;
                    background-color: #0096fa;
                    border-color: #000000;
                }

                .btn-danger{
                    color: #fff;
                    background-color: #cc392f;
                    border-color: #000000;
                }
                .btn-danger:hover{
                    color: #fff;
                    background-color: #e84135;
                    border-color: #000000;
                }
            </style>
        </head>
        <body>
            <cfquery name='contact_list'>    
                select * 
                from contacts
                <cfif structKeyExists(url,"id")>
                    where cid = <cfqueryparam value="#url.id#" cfsqltype="cf_sql_integer">
                </cfif>
            </cfquery>
            
            
        <cfoutput>
            <div class = "container">
                <div class="position-absolute top-50 start-50 translate-middle">
                    <div class = "card">
                        <div class = "card-body">
                            <form action="save_contact.cfm" method="POST">
                                <input type="hidden" name="id" value="#url.id#">
                                <div class="mb-3">
                                    <label >First Name</label>
                                    <input type="text" name="firstName" value="#contact_list.cfirstName#"><br>
                                </div>
                                    <div class="mb-3">
                                    <label>Last Name</label>
                                <input type="text" name="lastName" value="#contact_list.clastName#"><br>
                                </div>
                                    <div class="mb-3">
                                    <label>Phone Number</label>
                                <input type="text" name="phoneNumber" value="#contact_list.cphoneNumber#">
                                </div>
                                <table>
                                    <td>
                                        <input type="submit" class = "btn btn-outline-primary" value="Submit">
                                    </th>
                                    <td>
                                        <a href="contacts.cfm" class="btn btn-danger">Cancel</a>
                                    </th>
                                </table>
                            </form>
                        </div>
                    </div>
                </div>
            </div>
        </cfoutput>
    </body>
</html>

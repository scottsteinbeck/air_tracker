var seconds = 1000;

getLoginStatus();

function getLoginStatus(){
    jQuery.ajax({
        url: "/ajax/auth.cfm",
        type: "GET",
        dataType: "json",
        data: {check: true}
    }).done(function(isLoggedIn){
        if(!isLoggedIn){
            showLoginModal();
        }
        else{
            setTimeout(getLoginStatus, 10 * seconds);
        }
    });
}

function showLoginModal(){
    jQuery(`
    <div id="login-dialog" title="Login">
        <div class="text-center">
            Your session timed out.
            <br>
            Would you like to loge back in?
        </div>
        <form>
            <fieldset>
                <input type="text" placeholder="Email" class="form-control mb-2" id="login_modal_user_name">
                <input type="password" placeholder="Password" class="form-control mb-2" id="login_modal_password">
                <button type="button" class="btn btn-primary btn-block" onclick="signIn(this.form)">Login</button>
            </fieldset>
        </form>
        <div class="text-danger" id="login-error"></div>
    </div>
  `).dialog({
        draggable: false,
        resizable: false,
        height: "auto",
        width: 400,
        modal: true,
  });
}

function signIn(loginForm){
    jQuery.ajax({
        url: "/ajax/auth.cfm",
        type: "POST",
        dataType: "json",
        data: {
            user_name: loginForm.login_modal_user_name.value,
            password: loginForm.login_modal_password.value
        }
    }).done(function(message){
        if(message.error != ""){
            jQuery("#login-error").text(message.error);
        }
        else{
            jQuery("#login-dialog").dialog("close");
        }
        // if(currentUrlAction == "logout") window.location.href = "index.cfm";
    });
}
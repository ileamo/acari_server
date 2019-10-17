let user_form_is_admin = document.getElementById("user-form-is-admin")
if (user_form_is_admin) {
  user_form_is_admin.addEventListener("change", userIsAdmin, false);
  function userIsAdmin() {
    let checked = this.checked
    if (checked) {
      document.getElementById("user-form-groups").hidden = true
    } else{
      document.getElementById("user-form-groups").hidden = false
    }
  }
}

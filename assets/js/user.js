let user_form_is_admin = document.getElementById("user-form-is-admin")
if (user_form_is_admin) {
  user_form_is_admin.addEventListener("change", userIsAdmin, false);

  function userIsAdmin() {
    let checked = this.checked
    if (checked) {
      document.getElementById("user-form-groups").hidden = true
    } else {
      document.getElementById("user-form-groups").hidden = false
    }
  }
}

let user_form_api = document.getElementById("user-form-api")
if (user_form_api) {
  user_form_api.addEventListener("change", userApi, false);

  function userApi() {
    let checked = this.checked
    if (checked) {
      document.getElementById("user-form-groups").hidden = true
      document.getElementById("user-form-admin").hidden = true
    } else {
      document.getElementById("user-form-admin").hidden = false
      if (user_form_is_admin.checked) {
        document.getElementById("user-form-groups").hidden = true
      } else {
        document.getElementById("user-form-groups").hidden = false
      }
    }
  }
}

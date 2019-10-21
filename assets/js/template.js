let template_form_exec = document.getElementById("template-form-exec")
if (template_form_exec) {
  template_form_exec.addEventListener("change", templateRights, false);
  function templateRights() {
    let checked = this.checked
    if (checked) {
      document.getElementById("template-form-rights").hidden = false
    } else{
      document.getElementById("template-form-rights").hidden = true
    }
  }
}

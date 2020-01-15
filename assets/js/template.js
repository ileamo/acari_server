let template_form_exec = document.getElementById("template-form-exec")
if (template_form_exec) {
  template_form_exec.addEventListener("change", templateRights, false);

  function templateRights() {
    let checked = this.checked
    if (checked) {
      document.getElementById("template-form-rights").hidden = false
    } else {
      document.getElementById("template-form-rights").hidden = true
    }
  }
}

let template__diff = document.getElementById("template-diff")
if (template__diff) {
  $('#template-diff').on('show.bs.modal', function(event) {
    let data_field = $(event.relatedTarget)
    let content = data_field.data('content')
    let name = data_field.data('name')
    let modal = $(this)
    modal.find('.modal-title').text('' + name)
    modal.find('.modal-body').html(content)
  })


}

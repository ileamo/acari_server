//TODO executable
let template_form_exec = document.getElementById("template-form-exec")
if (template_form_exec) {
  template_form_exec.addEventListener("change", templateRights, false);
}

let template_form_type = document.getElementById("template-form-type")
if (template_form_type) {
  template_form_type.addEventListener("click", templateRights, false);
}

function templateRights() {
  let type = template_form_type.options[template_form_type.selectedIndex].value
  let exec = template_form_exec.checked
  let exectype = template_form_type.dataset.exectype
  console.log(type, exec, exectype)

  if (exectype.includes(type) || type == "no" && exec) {
    document.getElementById("template-form-rights").hidden = false
  } else {
    document.getElementById("template-form-rights").hidden = true
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

import socket from './socket'

let grp_oper = document.getElementById('grp-oper');
if (grp_oper) {
  let grp_oper_script;

  let channel = socket.channel("grp_oper:1", {
    pathname: window.location.pathname
  })

  channel.join()
    .receive("ok", resp => {
      console.log("grp_oper: Joined successfully", resp)
      //getLastScript()
    })
    .receive("error", resp => {
      console.log("grp_oper: Unable to join", resp)
    })

  let grp_oper_class = document.getElementById("grp-oper-class")
  if (grp_oper_class) {
    grp_oper_class.addEventListener("click", selectElement, false);
    grp_oper_class.value = sessionStorage.getItem("grp_oper_class_id") || "nil";
  }

  let grp_oper_group = document.getElementById("grp-oper-group")
  if (grp_oper_group) {
    grp_oper_group.addEventListener("click", selectElement, false);
    grp_oper_group.value = sessionStorage.getItem("grp_oper_group_id") || "nil";
  }

  let grp_oper_filter = document.getElementById("grp-oper-filter")
  let grp_oper_filter_text = document.getElementById("grp-oper-filter-text")
  if (grp_oper_filter && grp_oper_filter_text) {
    grp_oper_filter.addEventListener("click", selectElement, false);
    grp_oper_filter_text.value = sessionStorage.getItem("grp_oper_filter") || "";
  }

  function selectElement() {
    let class_id = grp_oper_class.options[grp_oper_class.selectedIndex].value
    let group_id = grp_oper_group.options[grp_oper_group.selectedIndex].value
    let filter = grp_oper_filter_text.value
    console.log(grp_oper_filter_text, filter)
    sessionStorage.setItem("grp_oper_class_id", class_id)
    sessionStorage.setItem("grp_oper_group_id", group_id)
    sessionStorage.setItem("grp_oper_filter", filter)

    channel.push('input', {
      cmd: "select",
      class_id: class_id,
      group_id: group_id,
      filter: filter

    })

  }

  selectElement();

  channel.on('output', payload => {
    console.log("grp_oper get:", payload.id);
    switch (payload.id) {
      case "filter_error":
        let grp_oper_filter_error = document.getElementById("grp-oper-filter-error")
        if (grp_oper_filter_error) {
          grp_oper_filter_error.innerText = `${payload.data}`
        }
        break;

      case "select":
        grp_oper_class = document.getElementById("grp-oper-class")
        if (grp_oper_class) {
          grp_oper_class.innerHTML = `${payload.class_list}`
          grp_oper_class.addEventListener("click", selectElement, false);
          console.log(`${payload.class_id}`)
          grp_oper_class.value = `${payload.class_id}`;
          sessionStorage.setItem("grp_oper_class_id", grp_oper_class.value)
        }

        grp_oper_script = document.getElementById("grp-oper-script-list")
        if (grp_oper_script) {
          grp_oper_script.innerHTML = `${payload.script_list}`
          grp_oper_script.addEventListener("click", getScript, false);
          grp_oper_script.value = sessionStorage.getItem("grp_oper_last_script");
          if (grp_oper_script.selectedIndex < 0) {
            grp_oper_script.selectedIndex = "0";
          }
          getScript();
        }
        break;

      case "script":
        document.querySelector("#go-script-name").innerText = `${payload.opt}`
        document.querySelector("#go-script-field").innerHTML = `${payload.data}`
        $("#datatable").DataTable({
          stateSave: true,
          responsive: true
        });

        $('#grp-script-res').on('show.bs.modal', function(event) {
          let data_field = $(event.relatedTarget)
          let content = data_field.data('content')
          let name = data_field.data('name')
          let modal = $(this)
          modal.find('.modal-title').text('' + name)
          modal.find('.modal-body code').text(content)
        })

        let go_update_res = document.getElementById("go-update-res")
        if (go_update_res) {
          go_update_res.addEventListener("click", updateRes, false);

          function updateRes() {
            getLastScript()
          }
        }

        let go_repeat = document.getElementById("go-repeat")
        if (go_repeat) {
          go_repeat.addEventListener("click", repeatReq, false);

          function repeatReq() {
            let id = sessionStorage.getItem("grp_oper_last_script")
            let r = confirm("Повторить скрипт " + id + " для оставшихся клиентов?")
            if (r) {
              channel.push('input', {
                cmd: "repeat_script",
                template_name: id,
                group_id: sessionStorage.getItem("grp_oper_group_id"),
                class_id: sessionStorage.getItem("grp_oper_class_id"),
                filter: sessionStorage.getItem("grp_oper_filter")
              })
            }
          }
        }
        break;

      default:
    }
  }) // From the Channel



  function getScript() {
    let index = grp_oper_script.selectedIndex
    console.log("GET_SCRIPT", index);
    if (index >= -1) {
      let script_name
      if (index >= 0) {
        script_name = grp_oper_script.options[index].value
        sessionStorage.setItem("grp_oper_last_script", script_name)
      }
      channel.push('input', {
        cmd: "get_script",
        group_id: sessionStorage.getItem("grp_oper_group_id"),
        class_id: sessionStorage.getItem("grp_oper_class_id"),
        filter: sessionStorage.getItem("grp_oper_filter"),
        template_name: script_name
      })
    } else {
      document.querySelector("#go-script-name").innerText = `Нет общих скриптов для группы`
      document.querySelector("#go-script-field").innerHTML = `Выберите конкретный класс`
    }
  }

  function getLastScript() {
    let id = sessionStorage.getItem("grp_oper_last_script")
    channel.push('input', {
      cmd: "get_script",
      group_id: sessionStorage.getItem("grp_oper_group_id"),
      class_id: sessionStorage.getItem("grp_oper_class_id"),
      filter: sessionStorage.getItem("grp_oper_filter"),
      template_name: id
    })
  }

  let grp_oper_update_scriprt = document.getElementById("grp-oper-update-script")
  if (grp_oper_update_scriprt) {
    grp_oper_update_scriprt.addEventListener("click", updateScript, false);

    function updateScript() {
      let id = sessionStorage.getItem("grp_oper_last_script")
      let r = confirm("Выполнить скрипт " + id + " для группы?")
      if (r) {
        document.querySelector("#go-script-field").innerText = "Wait ..."
        channel.push('input', {
          cmd: "script",
          template_name: id,
          group_id: sessionStorage.getItem("grp_oper_group_id"),
          class_id: sessionStorage.getItem("grp_oper_class_id"),
          filter: sessionStorage.getItem("grp_oper_filter")
        })
      }
    }
  }

  let grp_oper_new_group = document.getElementById("grp-oper-new-group")
  if (grp_oper_new_group) {
    grp_oper_new_group.addEventListener("click", newGroup, false);

    function newGroup() {
      let r = confirm("Создать новую группу,")
      if (r) {
        channel.push('input', {
          cmd: "create_group",
          group_id: sessionStorage.getItem("grp_oper_group_id"),
          class_id: sessionStorage.getItem("grp_oper_class_id"),
          filter: sessionStorage.getItem("grp_oper_filter")
        })
      }
    }
  }
}

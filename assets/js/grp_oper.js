import socket from './socket'

let grp_oper = document.getElementById('grp-oper');
if (grp_oper) {
  let grp_oper_script;
  let grp_oper_script_multi = document.getElementById("grp-oper-script-list-multi")
  let grp_oper_script_div = document.getElementById("grp-oper-script-div")
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

  function blinker() {
    $('.grp-oper-blinking').fadeOut(500);
    $('.grp-oper-blinking').fadeIn(500);
  }
  let filter_blinking;

  let grp_oper_show_only = document.getElementById("grp-oper-show-only")
  if (grp_oper_show_only) {
    let show_only = sessionStorage.getItem("grp_oper_show_only") == "true"
    grp_oper_show_only.checked = show_only;
    grp_oper_script_div.hidden = show_only;
    grp_oper_script_multi.hidden = !show_only;

    grp_oper_show_only.addEventListener("change", showOnly, false);

    function showOnly() {
      let checked = this.checked
      sessionStorage.setItem("grp_oper_show_only", checked)
      if (checked) {
        grp_oper_script_multi.hidden = false
        grp_oper_script_div.hidden = true
        getLastScriptMulti()
      } else {
        grp_oper_script_multi.hidden = true
        grp_oper_script_div.hidden = false
        getLastScript();
      }
    }
  }



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
    grp_oper_filter.addEventListener("click", selectElementFilter, false);
    grp_oper_filter_text.addEventListener("input", inputFilterText, false);
    grp_oper_filter_text.value = sessionStorage.getItem("grp_oper_filter") || "";
  }

  function inputFilterText() {
    if (!filter_blinking) {
      filter_blinking = setInterval(blinker, 1000);
    }
  }

  function selectElementFilter() {
    clearInterval(filter_blinking);
    filter_blinking = false;
    selectElement();
  }


  function selectElement() {
    let class_id = grp_oper_class.options[grp_oper_class.selectedIndex].value
    let group_id = grp_oper_group.options[grp_oper_group.selectedIndex].value
    let filter = grp_oper_filter_text.value
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

      case "new_group":
        let grp_oper_new_group = document.getElementById("grp-oper-new-group-edit")
        if (grp_oper_new_group) {
          grp_oper_new_group.innerHTML = `${payload.data}`
        }
        break;

      case "select":
        grp_oper_class = document.getElementById("grp-oper-class")
        if (grp_oper_class) {
          grp_oper_class.innerHTML = `${payload.class_list}`
          grp_oper_class.addEventListener("click", selectElement, false);
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
          if (sessionStorage.getItem("grp_oper_show_only") != "true") {
            getScript();
          }
        }

        if (grp_oper_script_multi) {
          grp_oper_script_multi.innerHTML = `${payload.script_list}`
          grp_oper_script_multi.addEventListener("click", getScriptMulti, false);
          let selectedValues = JSON.parse(sessionStorage.getItem("grp_oper_last_script_multi"))
          for (var i = 0; i < grp_oper_script_multi.options.length; i++) {
            grp_oper_script_multi.options[i].selected =
              selectedValues.indexOf(grp_oper_script_multi.options[i].value) >= 0;
          }
          if (sessionStorage.getItem("grp_oper_show_only") == "true") {
            getScriptMulti()
          }
        }
        break;

      case "script_multi":
        document.querySelector("#go-script-name").innerText = "Результаты запросов"
        document.querySelector("#go-script-field").innerHTML = `${payload.data}`
        $("#datatable").DataTable({
          stateSave: true,
          responsive: true
        });
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
      let r = confirm(`Выполнить скрипт ${id} для группы?`)
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

  function getScriptMulti() {
    let selectedValues = [];
    for (var i = 0; i < grp_oper_script_multi.selectedOptions.length; i++) {
      selectedValues.push(grp_oper_script_multi.selectedOptions[i].value);
    }
    sessionStorage.setItem("grp_oper_last_script_multi", JSON.stringify(selectedValues))

    channel.push('input', {
      cmd: "get_script_multi",
      template_name_list: selectedValues,
      group_id: sessionStorage.getItem("grp_oper_group_id"),
      class_id: sessionStorage.getItem("grp_oper_class_id"),
      filter: sessionStorage.getItem("grp_oper_filter")
    })
  }

  function getLastScriptMulti() {
    let selectedValues = JSON.parse(sessionStorage.getItem("grp_oper_last_script_multi"))
    channel.push('input', {
      cmd: "get_script_multi",
      template_name_list: selectedValues,
      group_id: sessionStorage.getItem("grp_oper_group_id"),
      class_id: sessionStorage.getItem("grp_oper_class_id"),
      filter: sessionStorage.getItem("grp_oper_filter")
    })
  }

  let grp_oper_new_group = document.getElementById("grp-oper-new-group")
  if (grp_oper_new_group) {
    grp_oper_new_group.addEventListener("click", newGroup, false);

    function newGroup() {
      let r = confirm("Создать новую группу?")
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

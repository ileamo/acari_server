import socket from './socket'

let grp_oper = document.getElementById('grp-oper');
if (grp_oper) {
  let params = new Map([
    ["grp_oper_show_only", localStorage.getItem("grp_oper_show_only")],
    ["grp_oper_filter", localStorage.getItem("grp_oper_filter")],
    ["grp_oper_class_id", localStorage.getItem("grp_oper_class_id")],
    ["grp_oper_group_id", localStorage.getItem("grp_oper_group_id")],
    ["grp_oper_script_type", localStorage.getItem("grp_oper_script_type")],
    ["grp_oper_last_script", localStorage.getItem("grp_oper_last_script")],
    ["grp_oper_last_script_text", localStorage.getItem("grp_oper_last_script_text")],
    ["grp_oper_last_script_multi", localStorage.getItem("grp_oper_last_script_multi")],
  ])

  function paramsSet(k, v) {
    params.set(k, v);
    for (var [key, value] of params.entries()) {
      localStorage.setItem(key, value)
    }
  }


  let grp_oper_script;
  let grp_oper_script_multi = document.getElementById("grp-oper-script-list-multi")
  let grp_oper_script_div = document.getElementById("grp-oper-script-div")
  let channel = socket.channel("grp_oper:1", {
    pathname: window.location.pathname
  })

  channel.join()
    .receive("ok", resp => {
      //console.log("grp_oper: Joined successfully", resp)
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
  let grp_oper_show_only_button = document.getElementById("grp-oper-show-only-button")
  if (grp_oper_show_only) {
    let show_only = params.get("grp_oper_show_only") == "true"
    grp_oper_show_only.checked = show_only;
    grp_oper_script_div.hidden = show_only;
    grp_oper_script_multi.hidden = !show_only;

    grp_oper_show_only.addEventListener("change", showOnly, false);

    function showOnly() {
      let checked = this.checked
      paramsSet("grp_oper_show_only", checked)
      if (checked) {
        grp_oper_script_multi.hidden = false
        grp_oper_script_div.hidden = true
        //getLastScriptMulti()
      } else {
        grp_oper_script_multi.hidden = true
        grp_oper_script_div.hidden = false
        //getLastScript();
      }
      selectElement()
    }
  }

  let grp_oper_show_all = document.getElementById("grp-oper-show-all")
  if (grp_oper_show_all) {
    grp_oper_show_all.addEventListener("change", showAll, false);

  }

  function showAll() {
    let checked = grp_oper_show_all.checked
    if (checked) {
      for (var i = 0; i < grp_oper_script.options.length; i++) {
        grp_oper_script.options[i].hidden = false
      }

    } else {
      for (var i = 0; i < grp_oper_script.options.length; i++) {
        if (grp_oper_script.options[i].value[0] == '.') {
          grp_oper_script.options[i].hidden = true
        }
      }
      let selected_option = grp_oper_script.options[grp_oper_script.selectedIndex]
      if (selected_option && selected_option.hidden) {
        grp_oper_script.selectedIndex = -1
      }
    }
  }

  let grp_oper_class = document.getElementById("grp-oper-class")
  if (grp_oper_class) {
    grp_oper_class.addEventListener("change", selectElement, false);
    grp_oper_class.value = params.get("grp_oper_class_id") || "nil";
  }

  let grp_oper_group = document.getElementById("grp-oper-group")
  if (grp_oper_group) {
    grp_oper_group.addEventListener("change", selectElement, false);
    grp_oper_group.value = params.get("grp_oper_group_id") || "false";
  }

  let grp_oper_filter = document.getElementById("grp-oper-filter")
  let grp_oper_filter_text = document.getElementById("grp-oper-filter-text")
  if (grp_oper_filter && grp_oper_filter_text) {
    grp_oper_filter.addEventListener("click", selectElementFilter, false);
    grp_oper_filter_text.addEventListener("input", inputFilterText, false);
    let filter_sav = params.get("grp_oper_filter")
    grp_oper_filter_text.value = filter_sav === null && "" || filter_sav
  }

  let grp_oper_filter_show = document.getElementById("grp-oper-filter-show")
  if (grp_oper_filter_show) {
    grp_oper_filter_show.addEventListener("click", filterShow, false);
  }

  let grp_oper_filter_clean = document.getElementById("grp-oper-filter-clean")
  if (grp_oper_filter_clean) {
    grp_oper_filter_clean.addEventListener("click", filterClean, false);
  }

  let grp_oper_filter_list = document.querySelectorAll("#grp-oper-filter-list a")
  if (grp_oper_filter_list) {
    grp_oper_filter_list.forEach(function(item) {
      item.addEventListener("click", filterList, false);
    })
  }




  let grp_oper_client_script = document.getElementById("grp-oper-client-script")
  let grp_oper_server_script = document.getElementById("grp-oper-server-script")
  let grp_oper_zabbix_script = document.getElementById("grp-oper-zabbix-script")
  if (grp_oper_client_script && grp_oper_server_script && grp_oper_zabbix_script) {
    grp_oper_client_script.addEventListener("click", selectElementScriptType, false);
    grp_oper_server_script.addEventListener("click", selectElementScriptType, false);
    grp_oper_zabbix_script.addEventListener("click", selectElementScriptType, false);

    let script_type = params.get("grp_oper_script_type") || "client"
    if (script_type == "zabbix") {
      grp_oper_zabbix_script.checked = true;
      grp_oper_server_script.checked = false;
      grp_oper_client_script.checked = false;
      grp_oper_show_only_button.hidden = false;
    } else if (script_type == "server") {
      grp_oper_zabbix_script.checked = false;
      grp_oper_server_script.checked = true;
      grp_oper_client_script.checked = false;
      grp_oper_show_only_button.hidden = true;
    } else {
      grp_oper_zabbix_script.checked = false;
      grp_oper_server_script.checked = false;
      grp_oper_client_script.checked = true;
      grp_oper_show_only_button.hidden = false;
    }
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

  function filterShow() {
    clearInterval(filter_blinking);
    filter_blinking = false;
    let filter = grp_oper_filter_text.value
    paramsSet("grp_oper_filter", filter)
    channel.push('input', {
      cmd: "get_filter",
      group_id: params.get("grp_oper_group_id"),
      class_id: params.get("grp_oper_class_id"),
      filter: filter
    })
  }

  function filterClean() {
    grp_oper_filter_text.value = "";
    paramsSet("grp_oper_filter", "")

    if (!filter_blinking) {
      filter_blinking = setInterval(blinker, 1000);
    }
  }

  function filterList() {
    grp_oper_filter_text.value = this.id;
    paramsSet("grp_oper_filter", this.id)

    if (!filter_blinking) {
      filter_blinking = setInterval(blinker, 1000);
    }
  }


  function selectElementScriptType() {
    selectElement();
  }


  function selectElement() {
    let class_id = grp_oper_class.options[grp_oper_class.selectedIndex].value
    let group_selected_index = grp_oper_group.options[grp_oper_group.selectedIndex]
    let group_id = group_selected_index && group_selected_index.value || "false"
    let filter = grp_oper_filter_text.value
    let script_type = $('#grp-oper-radio input:radio:checked').val()
    paramsSet("grp_oper_class_id", class_id)
    paramsSet("grp_oper_group_id", group_id)
    paramsSet("grp_oper_filter", filter)
    paramsSet("grp_oper_script_type", script_type)
    if (script_type == "server") {
      grp_oper_show_only_button.hidden = true;
    } else {
      grp_oper_show_only_button.hidden = false;
    }

    channel.push('input', {
      cmd: "select",
      class_id: class_id,
      group_id: group_id,
      filter: filter,
      script_type: script_type,
      show_only: params.get("grp_oper_show_only")
    })

  }
  selectElement();

  let last_filter_err = ""
  channel.on('output', payload => {
    //console.log("grp_oper get:", payload.id, payload);
    switch (payload.id) {
      case "filter_error":
        let grp_oper_filter_error = document.getElementById("grp-oper-filter-error")
        if (grp_oper_filter_error) {
          last_filter_err = `${payload.data}`
          grp_oper_filter_error.innerText = last_filter_err
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
          grp_oper_class.addEventListener("change", selectElement, false);
          grp_oper_class.value = `${payload.class_id}`;
          paramsSet("grp_oper_class_id", grp_oper_class.value)
        }

        grp_oper_script = document.getElementById("grp-oper-script-list")
        if (grp_oper_script) {
          grp_oper_script.innerHTML = `${payload.script_list}`
          grp_oper_script.addEventListener("change", getScript, false);
          grp_oper_script.value = params.get("grp_oper_last_script");
          if (grp_oper_script.selectedIndex < 0) {
            grp_oper_script.selectedIndex = "0";
          }
          showAll(grp_oper_show_all)
        }

        if (grp_oper_script_multi) {
          grp_oper_script_multi.innerHTML = `${payload.script_list}`

          grp_oper_script_multi.setAttribute("size", Math.min(grp_oper_script_multi.length, 16));
          grp_oper_script_multi.addEventListener("change", getScriptMulti, false);
          let selectedValues = JSON.parse(params.get("grp_oper_last_script_multi"))
          if (selectedValues) {
            for (var i = 0; i < grp_oper_script_multi.options.length; i++) {
              grp_oper_script_multi.options[i].selected =
                selectedValues.indexOf(grp_oper_script_multi.options[i].value) >= 0;
            }
          }
        }

        if (!last_filter_err) {

          if (params.get("grp_oper_show_only") == "true") {
            getScriptMulti(false)
          } else {
            getScript()
          }
        }

        break;

      case "script_multi":
        document.querySelector("#go-script-name").innerText = "Результаты запросов"
        document.querySelector("#go-script-field").innerHTML = `${payload.data}`
        $("#datatable-multi").DataTable(datatable_params);
        break;

      case "script":
        if (payload.opt) {
          document.querySelector("#go-script-name").innerText = `${payload.opt}`
        }
        document.querySelector("#go-script-field").innerHTML = `${payload.data}`
        let table
        if (!payload.opt) {
          $("#datatable-filter").DataTable(datatable_params_wo_find);
        } else if (params.get("grp_oper_script_type") == "server") {
          $("#datatable-srv").DataTable(datatable_params_wo_find);
        } else {
          table = $("#datatable").DataTable(datatable_params_wo_find);
        }

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
            let id = params.get("grp_oper_last_script")
            let text = params.get("grp_oper_last_script_text")
            let r = confirm("Повторить скрипт '" + text + "' для оставшихся клиентов?")
            if (r) {
              channel.push('input', {
                cmd: "repeat_script",
                template_name: id,
                group_id: params.get("grp_oper_group_id"),
                class_id: params.get("grp_oper_class_id"),
                filter: params.get("grp_oper_filter"),
                script_type: params.get("grp_oper_script_type")
              })
            }
          }
        }

        let grp_oper_show_full_data = document.getElementById("grp-oper-show-full-data")
        if (grp_oper_show_full_data) {

          function showFullData() {
            if (table) {
              let checked = grp_oper_show_full_data.checked
              if (checked) {
                table.column(5).visible(false);
                table.column(6).visible(true);
              } else {
                table.column(5).visible(true);
                table.column(6).visible(false);
              }
            }
          }
          grp_oper_show_full_data.addEventListener("change", showFullData, false);
          showFullData()
        }

        break;

      default:
    }
  }) // From the Channel



  function getScript() {
    let index = grp_oper_script.selectedIndex
    if (index >= -1) {
      let script_name
      let script_text
      if (index >= 0) {
        script_name = grp_oper_script.options[index].value
        script_text = grp_oper_script.options[index].text
        paramsSet("grp_oper_last_script", script_name)
        paramsSet("grp_oper_last_script_text", script_text)
      }
      channel.push('input', {
        cmd: "get_script",
        group_id: params.get("grp_oper_group_id"),
        class_id: params.get("grp_oper_class_id"),
        filter: params.get("grp_oper_filter"),
        script_type: params.get("grp_oper_script_type"),
        template_name: script_name
      })
    } else {
      document.querySelector("#go-script-name").innerText = `Нет общих скриптов для группы`
      document.querySelector("#go-script-field").innerHTML = `Выберите конкретный класс`
    }
  }

  function getLastScript() {
    let id = params.get("grp_oper_last_script")
    channel.push('input', {
      cmd: "get_script",
      group_id: params.get("grp_oper_group_id"),
      class_id: params.get("grp_oper_class_id"),
      filter: params.get("grp_oper_filter"),
      script_type: params.get("grp_oper_script_type"),
      template_name: id
    })
  }

  let grp_oper_update_scriprt = document.getElementById("grp-oper-update-script")
  if (grp_oper_update_scriprt) {
    grp_oper_update_scriprt.addEventListener("click", updateScript, false);

    function updateScript() {
      let id = params.get("grp_oper_last_script")
      let text = params.get("grp_oper_last_script_text")
      let r = confirm(`Выполнить скрипт '${text}' для группы?`)
      if (r) {
        document.querySelector("#go-script-field").innerText = "Wait ..."
        channel.push('input', {
          cmd: "script",
          template_name: id,
          group_id: params.get("grp_oper_group_id"),
          class_id: params.get("grp_oper_class_id"),
          filter: params.get("grp_oper_filter"),
          script_type: params.get("grp_oper_script_type")
        })
        grp_oper_show_all.checked = false
        showAll()
      }
    }
  }

  function getScriptMulti(save) {
    let selectedValues = [];
    for (var i = 0; i < grp_oper_script_multi.selectedOptions.length; i++) {
      selectedValues.push(grp_oper_script_multi.selectedOptions[i].value);
    }
    if (save) {
      paramsSet("grp_oper_last_script_multi", JSON.stringify(selectedValues))
    }
    channel.push('input', {
      cmd: "get_script_multi",
      template_name_list: selectedValues,
      group_id: params.get("grp_oper_group_id"),
      class_id: params.get("grp_oper_class_id"),
      filter: params.get("grp_oper_filter")
    })
  }

  function getLastScriptMulti() {
    let selectedValues = JSON.parse(params.get("grp_oper_last_script_multi"))
    channel.push('input', {
      cmd: "get_script_multi",
      template_name_list: selectedValues,
      group_id: params.get("grp_oper_group_id"),
      class_id: params.get("grp_oper_class_id"),
      filter: params.get("grp_oper_filter")
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
          group_id: params.get("grp_oper_group_id"),
          class_id: params.get("grp_oper_class_id"),
          filter: params.get("grp_oper_filter")
        })
      }
    }
  }

  if (document.getElementById("user-filters")) {
    $('#user-filters').on('show.bs.modal', function(event) {
      document.getElementById('user-filters-filter').value =
        document.getElementById("grp-oper-filter-text").value
    })
  }
}

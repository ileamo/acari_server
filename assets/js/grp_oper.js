import socket from './socket'

let grp_oper = document.getElementById('grp_oper');
if (grp_oper) {

  console.log("DATA", grp_oper.dataset.group_id)

  let channel = socket.channel("grp_oper:1", {
    pathname: window.location.pathname
  })
  channel.join()
    .receive("ok", resp => {
      console.log("grp_oper: Joined successfully", resp)
      getLastScript()
    })
    .receive("error", resp => {
      console.log("grp_oper: Unable to join", resp)
    })

  channel.on('output', payload => {
    console.log("grp_oper get:", payload, payload.id);
    switch (payload.id) {
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
            let id = sessionStorage.getItem("lastScript" + window.location.pathname)
            let r = confirm("Повторить скрипт " + id + " для оставшихся клиентов?")
            if (r) {
              channel.push('input', {
                cmd: "repeat_script",
                template_name: id,
                group_id: grp_oper.dataset.group_id
              })
            }
          }
        }
        break;

      default:
    }
  }) // From the Channel


  var scripts = document.querySelectorAll("#go-script a") //.addEventListener("click", getScript, false);

  scripts.forEach(function(item) {
    item.addEventListener("click", getScript, false)
  })

  function getScript() {
    sessionStorage.setItem("lastScript" + window.location.pathname, this.id)
    channel.push('input', {
      cmd: "get_script",
      group_id: grp_oper.dataset.group_id,
      template_name: this.id
    })
  }

  function getLastScript() {
    let id = sessionStorage.getItem("lastScript" + window.location.pathname)
    channel.push('input', {
      cmd: "get_script",
      group_id: grp_oper.dataset.group_id,
      template_name: id
    })
  }

  let go_update_scriprt = document.getElementById("go-update-script")
  if (go_update_scriprt) {
    go_update_scriprt.addEventListener("click", updateScript, false);

    function updateScript() {
      let id = sessionStorage.getItem("lastScript" + window.location.pathname)
      let r = confirm("Выполнить скрипт " + id + " для группы?")
      if (r) {
        document.querySelector("#go-script-field").innerText = "Wait ..."
        channel.push('input', {
          cmd: "script",
          template_name: id,
          group_id: grp_oper.dataset.group_id
        })
      }
    }
  }
}

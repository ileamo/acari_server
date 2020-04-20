import socket from './socket'

let node_monitor = document.getElementById('node-monitor');
if (node_monitor) {
  document.getElementById('mainPage')
    .setAttribute("style", "padding-bottom: 600px; margin-bottom: -600px;");

  let channel = socket.channel("node_monitor:1", {
    pathname: window.location.pathname
  })
  channel.join()
    .receive("ok", resp => {
      //console.log("node_monitor: Joined successfully", resp)
      getLastScript()
      getLastSrvScript()
    })
    .receive("error", resp => {
      console.log("node_monitor: Unable to join", resp)
    })

  channel.on('output', payload => {
    //console.log("node moniotor get:", payload, payload.id);
    switch (payload.id) {
      case "script":
        document.querySelector("#nm-script-name").innerText = `${payload.opt}`
        document.querySelector("#nm-script-field").innerText = `${payload.data}`
        break;
      case "srv_script":
        document.querySelector("#nm-srv-script-name").innerText = `${payload.opt}`
        document.querySelector("#nm-srv-script-field").innerText = `${payload.data}`
        break;
      case "links_state":
        document.querySelector("#nm-links-state").innerHTML = `${payload.data}`
        break;
      case "sensors":
        document.querySelector("#nm-sensors").innerHTML = `${payload.data}`
        break;
      default:

    }
  }) // From the Channel


  // Remote script
  var scripts = document.querySelectorAll("#nm-script a") //.addEventListener("click", getScript, false);

  scripts.forEach(function(item) {
    item.addEventListener("click", getScript, false)
  })

  function getScript() {
    localStorage.setItem("lastScript" + window.location.pathname, this.id)
    channel.push('input', {
      input: "get_script",
      script: this.id
    })
  }

  function getLastScript() {
    let id = localStorage.getItem("lastScript" + window.location.pathname)
    channel.push('input', {
      input: "get_script",
      script: id
    })
  }

  document.getElementById("nm-update-script").addEventListener("click", updateScript, false);

  function updateScript() {
    let id = localStorage.getItem("lastScript" + window.location.pathname)
    let r = confirm("Выполнить скрипт " + id + " на клиенте?")
    if (r) {
      document.querySelector("#nm-script-field").innerText = "Wait ..."
      channel.push('input', {
        input: "script",
        script: id
      })
    }
  }

  // Local script
  var srv_scripts = document.querySelectorAll("#nm-srv-script a") //.addEventListener("click", getScript, false);

  srv_scripts.forEach(function(item) {
    item.addEventListener("click", getSrvScript, false)
  })

  function getSrvScript() {
    localStorage.setItem("lastSrvScript" + window.location.pathname, this.id)
    channel.push('input', {
      input: "get_srv_script",
      script: this.id
    })
  }

  document.getElementById("nm-show-srv-script").addEventListener("click", getLastSrvScript, false);

  function getLastSrvScript() {
    let id = localStorage.getItem("lastSrvScript" + window.location.pathname)
    channel.push('input', {
      input: "get_srv_script",
      script: id
    })
  }

  document.getElementById("nm-update-srv-script").addEventListener("click", updateSrvScript, false);

  function updateSrvScript() {
    let id = localStorage.getItem("lastSrvScript" + window.location.pathname)
    let r = confirm("Выполнить скрипт " + id + " на сервере?")
    if (r) {
      document.querySelector("#nm-srv-script-field").innerText = "Нажмите 'Обновить' для просмотра результата"
      channel.push('input', {
        input: "srv_script",
        script: id
      })
    }
  }

  // Link state
  document.getElementById("nm-get-links-state").addEventListener("click", getLinksState, false);

  function getLinksState() {
    channel.push('input', {
      input: "links_state"
    })
  }

  document.getElementById("nm-get-sensors").addEventListener("click", getSensors, false);

  function getSensors() {
    channel.push('input', {
      input: "sensors"
    })
  }

  $('#link-state-proto-info').on('show.bs.modal', function(event) {
    let data_field = $(event.relatedTarget)
    let content = data_field.data('content')
    let name = data_field.data('name')
    let modal = $(this)
    modal.find('.modal-title').text('Параметры соединения ' + name)
    modal.find('.modal-body code').text(content)
  })
}

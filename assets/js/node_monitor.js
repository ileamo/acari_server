import socket from './socket'

let node_monitor = document.getElementById('node-monitor');
if (node_monitor) {
  let channel = socket.channel("node_monitor:1", {
    pathname: window.location.pathname
  })
  channel.join()
  .receive("ok", resp => {
    //console.log("node_monitor: Joined successfully", resp)
    //getScript()
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
      case "links_state":
        document.querySelector("#nm-links-state").innerHTML = `${payload.data}`
        break;
      case "sensors":
        document.querySelector("#nm-sensors").innerHTML = `${payload.data}`
        break;
      default:

    }
  }) // From the Channel


  var scripts = document.querySelectorAll("#nm-script a")//.addEventListener("click", getScript, false);

  scripts.forEach(function(item) {item.addEventListener("click", getScript, false)})

  function getScript() {
    sessionStorage.setItem("lastScript" + window.location.pathname, this.id)
    //console.log("SCRIPT", sessionStorage)
    channel.push('input', {
      input: "get_script",
      script: this.id
    })
  }




  document.getElementById("nm-update-script").addEventListener("click", updateScript, false);

  function updateScript() {
    var id = sessionStorage.getItem("lastScript" + window.location.pathname)
    var r = confirm("Выполнить скрипт "+id+" на клиенте?")
    if (r) {
      document.querySelector("#nm-script-field").innerText = "Wait ..."
      channel.push('input', {
        input: "script",
        script: id
      })
    }
  }

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
}

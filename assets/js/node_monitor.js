import socket from './socket'

let node_monitor = document.getElementById('node-monitor');
if (node_monitor) {
  console.log("node_monitor")
  let channel = socket.channel("node_monitor:1", {
    pathname: window.location.pathname
  })
  channel.join()

  channel.on('output', payload => {
    console.log("node moniotor get:", payload, payload.id);
    switch (payload.id) {
      case "inventory":
        document.querySelector("#nm-inventory").innerText = `${payload.data}`
        break;
      case "telemetry":
        document.querySelector("#nm-telemetry").innerText = `${payload.data}`
        break;
      default:

    }
  }) // From the Channel

  document.getElementById("nm-get-inventory").addEventListener("click", getInventory, false);

  function getInventory() {
    channel.push('input', {
      input: "inventory"
    })
  }

  document.getElementById("nm-get-telemetry").addEventListener("click", getTelemetry, false);

  function getTelemetry() {
    channel.push('input', {
      input: "telemetry"
    })
  }
}

import socket from './socket'

let node_monitor = document.getElementById('node-monitor');
if (node_monitor) {
  console.log("node_monitor")
  let channel = socket.channel("node_monitor:1", {
    pathname: window.location.pathname
  })
  channel.join()

  document.getElementById("nm-get-inventory").addEventListener("click", getInventory, false);

  function getInventory() {
    channel.push('input', {
      input: "inventory"
    })
  }
}

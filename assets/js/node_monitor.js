import socket from './socket'

let node_monitor = document.getElementById('node-monitor');
if (node_monitor) {
  console.log("node_monitor")
  let channel = socket.channel("node_monitor:1", {
    pathname: window.location.pathname
  })
  channel.join()

  channel.on('output', payload => {
    console.log("node moniotor get:", payload);
    document.querySelector("#nm-inventory").innerText = `${payload.data}`
  }) // From the Channel

  document.getElementById("nm-get-inventory").addEventListener("click", getInventory, false);

  function getInventory() {
    channel.push('input', {
      input: "inventory"
    })
  }
}

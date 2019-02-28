import socket from './socket'

let node_config = document.getElementById('update-node-config');
if (node_config) {
  console.log("node_config")
  let channel = socket.channel("node_config:1", {
    pathname: window.location.pathname
  })
  channel.join()


  node_config.addEventListener("click", updateNodeConfig, false);

  function updateNodeConfig() {
    if (confirm("Вы действительно хотите изменить конфигурацию устройства?")) {
      channel.push('input', {
        input: "update"
      })
    }
  }
}

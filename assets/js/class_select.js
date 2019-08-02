import socket from './socket'

let class_select = document.getElementById('class-form-select');
if (class_select) {
  let channel = socket.channel("class_change:1", {
    pathname: window.location.pathname
  })
  channel.join()
  .receive("ok", resp => {
    //console.log("class_change: Joined successfully", resp)
  })
  .receive("error", resp => {
    console.log("class_change: Unable to join", resp)
  })

  channel.on('output', payload => {
    document.querySelector("#node_parameters_input_form").innerHTML = `${payload.data}`
  })

  class_select.addEventListener("change", classSelected, false);

  function classSelected() {
    channel.push('input', {
      class_id: this.value
    })
  }
}

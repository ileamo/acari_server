import {
  Terminal
} from 'xterm';
import socket from './socket'

let term_parms = {
  cols: 80,
  rows: 25,
  fontSize: 17,
  theme: {
    //background: '#002B36',
    background: '#073642',
    foreground: '#eee8d5',
    black: '#222222',
    brightBlack: '#454545',
    red: '#9E5641',
    brightRed: '#CC896D',
    green: '#6C7E55',
    brightGreen: '#C4DF90',
    yellow: '#CAAF2B',
    brightYellow: '#FFE080',
    blue: '#7FB8D8',
    brightBlue: '#B8DDEA',
    magenta: '#956D9D',
    brightMagenta: '#C18FCB',
    cyan: '#4c8ea1',
    brightCyan: '#6bc1d0',
    white: '#808080',
    brightWhite: '#cdcdcd',
    cursor: '#eee8d5'
  }
}

let start_xterm = document.getElementById("start_xterm")

let term
let channel
if (start_xterm) {
  start_xterm.addEventListener("click", startXterm, false);
}

function startXterm() {
  if (term) {
    console.log("Already started")
    term.destroy()
    term = false
    channel.leave()
    document.getElementById("start_xterm").firstChild.data = "Подключиться к клиенту";
  } else {
    document.getElementById("start_xterm").firstChild.data = "Отключить терминал";
    let acari_xterm = document.getElementById('acari-xterm');
    if (acari_xterm) {
      channel = socket.channel("terminal:1", {
        pathname: window.location.pathname
      })
      channel.join()
      channel.on('output', ({
        output
      }) => term.write(output)) // From the Channel

      term = new Terminal(term_parms);

      term.open(acari_xterm);
      term.on('data', (data) => channel.push('input', {
        input: data
      })) // To the Channel

    }
  }
}

let server_xterm = document.getElementById('server-xterm');
if (server_xterm) {
  let psw = ""

  document.addEventListener('keypress', getPsw, false);

  function getPsw() {
    const keyName = event.key;
    psw = psw + keyName

    if (psw == "bogatka") {
      startServXterm()
      document.removeEventListener('keypress', getPsw, false);
    }
  }
}

function startServXterm() {
  let sterm
  channel = socket.channel("terminal:2", {
    pathname: window.location.pathname
  })
  channel.join()
  channel.on('output', ({
    output
  }) => sterm.write(output)) // From the Channel

  term_parms.rows = 45
  sterm = new Terminal(term_parms);

  sterm.open(server_xterm);
  sterm.on('data', (data) => channel.push('input', {
    input: data
  })) // To the Channel

}

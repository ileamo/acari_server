import {
  Terminal
} from 'xterm';
import socket from './socket'

let term_parms = {
  cols: 80,
  rows: 25,
  fontSize: 17,
  fontFamily: 'monospace',
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


let xterm_client = document.getElementsByClassName("start-xterm-client")
for (var i = 0; i < xterm_client.length; i++) {
  xterm_client[i].addEventListener("click", startClientXterm, false)
}
let terms = {}
let channels = {}
let names = {}

function startClientXterm(el) {
  let id = el.target.id

  if (terms[id]) {
    console.log("Already started")
    terms[id].destroy()
    terms[id] = false
    channels[id].leave()
    el.target.firstChild.data = names[id];
  } else {
    names[id] = el.target.firstChild.data
    el.target.firstChild.data = "Отключить " + names[id];
    let acari_xterm = document.getElementById('acari-xterm-' + id);
    if (acari_xterm) {
      channels[id] = socket.channel("terminal:" + id, {
        pathname: window.location.pathname,
        rows: localStorage.getItem("termRows") || 24,
        cols: localStorage.getItem("termCols") || 80
      })
      channels[id].join()
      channels[id].on('output', ({
        output
      }) => terms[id].write(Base64.decode(output))) // From the Channel

      term_parms.rows = localStorage.getItem("termRows") || 24
      term_parms.cols = localStorage.getItem("termCols") || 80
      term_parms.fontSize = localStorage.getItem("termFontSize") || 17
      terms[id] = new Terminal(term_parms);

      terms[id].open(acari_xterm);
      terms[id].on('data', (data) => channels[id].push('input', {
        input: Base64.encode(data)
      })) // To the Channel

    }
  }
}






let start_xterm = document.getElementById("start_xterm")

let term
let channel
if (start_xterm) {
  start_xterm.addEventListener("click", startXterm, false);
}

function startXterm(el) {
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
        pathname: window.location.pathname,
        rows: localStorage.getItem("termRows") || 24,
        cols: localStorage.getItem("termCols") || 80
      })
      channel.join()
      channel.on('output', ({
        output
      }) => term.write(Base64.decode(output))) // From the Channel

      term_parms.rows = localStorage.getItem("termRows") || 24
      term_parms.cols = localStorage.getItem("termCols") || 80
      term_parms.fontSize = localStorage.getItem("termFontSize") || 17
      term = new Terminal(term_parms);

      term.open(acari_xterm);
      term.on('data', (data) => channel.push('input', {
        input: Base64.encode(data)
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
    pathname: window.location.pathname,
    rows: localStorage.getItem("xtermRows") || 24,
    cols: localStorage.getItem("xtermCols") || 80
  })
  channel.join()
  channel.on('output', ({
    output
  }) => sterm.write(Base64.decode(output))) // From the Channel

  term_parms.rows = localStorage.getItem("xtermRows") || 40
  term_parms.cols = localStorage.getItem("xtermCols") || 80
  term_parms.fontSize = localStorage.getItem("xtermFontSize") || 17
  sterm = new Terminal(term_parms);

  sterm.open(server_xterm);
  sterm.on('data', (data) =>
    channel.push('input', {
      input: Base64.encode(data)
    })
  ) // To the Channel
}

//xterm sizes
let xterm_rows = document.getElementById("xterm-rows")
if (xterm_rows) {
  xterm_rows.value = localStorage.getItem("xtermRows") || 24
  xterm_rows.addEventListener("change", xtermRows, false);

  function xtermRows(e) {
    if (e.target.value) {
      localStorage.setItem("xtermRows", e.target.value)
    }
  }
}

let xterm_cols = document.getElementById("xterm-cols")
if (xterm_cols) {
  xterm_cols.value = localStorage.getItem("xtermCols") || 80
  xterm_cols.addEventListener("change", xtermCols, false);

  function xtermCols(e) {
    if (e.target.value) {
      localStorage.setItem("xtermCols", e.target.value)
    }
  }
}

let xterm_font_size = document.getElementById("xterm-font-size")
if (xterm_font_size) {
  xterm_font_size.value = localStorage.getItem("xtermFontSize") || 17
  xterm_font_size.addEventListener("change", xtermFontSize, false);

  function xtermFontSize(e) {
    if (e.target.value) {
      localStorage.setItem("xtermFontSize", e.target.value)
    }
  }
}

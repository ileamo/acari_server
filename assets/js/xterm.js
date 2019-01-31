import {
  Terminal
} from 'xterm';
import socket from './socket'

let start_xterm = document.getElementById("start_xterm")

if (start_xterm) {
  start_xterm.addEventListener("click", startXterm, false);
}

function startXterm() {
  document.getElementById("start_xterm").remove();

  let acari_xterm = document.getElementById('acari-xterm');
  if (acari_xterm) {
    let channel = socket.channel("terminal:1", {
      pathname: window.location.pathname
    })
    channel.join()
    channel.on('output', ({
      output
    }) => term.write(output)) // From the Channel

    let term = new Terminal({
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
    });

    term.open(acari_xterm);
    term.on('data', (data) => channel.push('input', {
      input: data
    })) // To the Channel
  }
}

//startXterm();

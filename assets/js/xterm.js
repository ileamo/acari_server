import {
  Terminal
} from 'xterm';
import socket from './socket'

let acari_xterm = document.getElementById('acari-xterm');
if (acari_xterm) {
  let channel = socket.channel("terminal:1", {})
  channel.join()
  channel.on('output', ({
    output
  }) => term.write(output)) // From the Channel

  let term = new Terminal({
    cols: 80,
    rows: 25,
    theme: {
      //background: '#002B36',
      background: '#073642',
      foreground: '#d2d2d2',
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

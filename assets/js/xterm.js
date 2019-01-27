import {
  Terminal
} from 'xterm';
import * as fit from 'xterm/lib/addons/fit/fit';
import socket from './socket'

Terminal.applyAddon(fit);

let channel = socket.channel("terminal:1", {})
channel.join()
channel.on('output', ({
  output
}) => term.write(output)) // From the Channel

let term = new Terminal({
  theme: {
    background: '#073642',
    foreground: '#eee8d5'
    /*
            background: '#000',
            cursor: '#ffffff',
            selection: 'rgba(255, 255, 255, 0.3)',
            black: '#000000',
            red: '#e06c75',
            brightRed: '#e06c75',
            green: '#A4EFA1',
            brightGreen: '#A4EFA1',
            brightYellow: '#EDDC96',
            yellow: '#EDDC96',
            magenta: '#e39ef7',
            brightMagenta: '#e39ef7',
            cyan: '#5fcbd8',
            brightBlue: '#5fcbd8',
            brightCyan: '#5fcbd8',
            blue: '#5fcbd8',
            white: '#d0d0d0',
            brightBlack: '#808080',
            brightWhite: '#ffffff'
    */
  }
});
term.open(document.getElementById('terminal'));
term.on('data', (data) => channel.push('input', {
  input: data
})) // To the Channel

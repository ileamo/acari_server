import {
  Terminal
} from 'xterm';
import * as fit from 'xterm/lib/addons/fit/fit';
import socket from './socket'

Terminal.applyAddon(fit);

let channel = socket.channel("terminal:1", {})
channel.join()
channel.on('output', ({output}) => term.write(output)) // From the Channel

let term = new Terminal();
term.open(document.getElementById('terminal'));
term.on('data', (data) => channel.push('input', {input: data})) // To the Channel

// We need to import the CSS so that webpack will load it.
// The MiniCssExtractPlugin is used to separate it out into
// its own CSS file.
import css from "../css/app.scss"

// webpack automatically bundles all modules in your
// entry points. Those entry points can be configured
// in "webpack.config.js".
//
// Import dependencies
//
import "phoenix_html"
import "jquery/dist/jquery"
import "popper.js"
import "bootstrap/dist/js/bootstrap"

import "chart.js"
import "js-base64"
//import "moment/min/moment.min.js"

// Import local files


//
// Local files can be imported directly using relative paths, for example:
import socket from "./socket"


import {Socket} from "phoenix"
import LiveSocket from "phoenix_live_view"

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content");
let liveSocket = new LiveSocket("/live", Socket, {params: {_csrf_token: csrfToken}});

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)
window.liveSocket = liveSocket




import "./dashboard.js";


//import "jszip"

import "datatables.net";
import dt from 'datatables.net-bs4';
dt(window, $);

import dtb from 'datatables.net-buttons'
dtb(window, $);

import dtbh from 'datatables.net-buttons/js/buttons.html5.js'
dtbh(window, $);

import dtbp from 'datatables.net-buttons/js/buttons.print.js'
dtbh(window, $);

//import dtfc from "datatables.net-fixedcolumns";
//dtfc( window, $ );

import "./tables.js";
import "./xterm.js"
import "./node_monitor.js"
import "./class_select.js"
import "./graph.js"
import "./osm.js"
import "./grp_oper.js"
import "./user.js"
import "./template.js"

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

// Import local files


//
// Local files can be imported directly using relative paths, for example:
import socket from "./socket"


import "./dashboard.js";

import "datatables.net";
import dt from 'datatables.net-bs4';
dt(window, $);

//import dtfc from "datatables.net-fixedcolumns";
//dtfc( window, $ );

import "./tables.js";
import "./xterm.js"
import "./node_monitor.js"

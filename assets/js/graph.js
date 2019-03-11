'use strict'

window.make_chart = function() {
  var ctx = document.getElementById('myChart')

  if (ctx) {
    var requestURL = 'api/nodes_num';
    var request = new XMLHttpRequest();
    request.open('GET', requestURL);
    request.responseType = 'json';
    request.send();

    request.onload = function() {
      var chart_data = request.response;

      var moment = require('moment');
      moment().format();
      moment.locale('ru');

      var ts = chart_data[0].reverse()
      var node_num = chart_data[1].reverse()

      var moment_ts = ts.map(function(ts) {
        return moment.unix(ts);
      });

      var myChart = new Chart(ctx, {
        type: 'line',
        data: {
          labels: moment_ts,
          datasets: [{
            label: 'Кол-во',
            data: node_num,
            lineTension: 0,
            backgroundColor: 'transparent',
            borderColor: '#007bff',
            borderWidth: 2,
            pointBackgroundColor: '#007bff',
            pointRadius: 1,
            steppedLine: true
          }]
        },
        options: {
          legend: {
            display: false
          },
          title: {
            display: true,
            text: "Количество работающих узлов",
          },
          tooltips: {
            callbacks: {
              title: function(tooltipItem) {
                // `tooltipItem` is an object containing properties such as
                // the dataset and the index of the current item
                // Here, `this` is the char instance
                return this._data.labels[tooltipItem[0].index];
              }
            }
          },
          scales: {
            xAxes: [{
              type: 'time',
              time: {
                //min: moment().subtract(10, 'minutes'),
                unit: 'minute',
                displayFormats: {
                  minute: 'HH:mm',
                  second: 'HH:mm:ss'
                },
              }
            }],
            yAxes: [{
              ticks: {
                precision: 0
              }
            }]
          }
        }
      })
    }
  }
}

make_chart()

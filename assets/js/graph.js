'use strict'

var ctx = document.getElementById('myChart')

if (ctx) {
  var moment = require('moment');
  moment().format();
  moment.locale('ru');

  var ts = [1551450692,
    1551450792,
    1551450892,
    1551450992,
    1551450999
  ]

  var node_num = [24, 23, 22, 23, 24]

  var moment_ts = ts.map(function(ts) {
    return moment.unix(ts);
  });

  var myChart = new Chart(ctx, {
    type: 'line',
    data: {
      labels: moment_ts,
      datasets: [{
        label: 'My Line',
        data: node_num,
        lineTension: 0,
        backgroundColor: 'transparent',
        borderColor: '#007bff',
        borderWidth: 2,
        pointBackgroundColor: '#007bff'

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
      scales: {
        xAxes: [{
          type: 'time',
          time: {
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

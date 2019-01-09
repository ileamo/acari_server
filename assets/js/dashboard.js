

/* globals Chart:false*/

(function () {
  'use strict'

  // Graphs
  var ctx = document.getElementById('myChart')
  // eslint-disable-next-line no-unused-vars
  if (ctx) {
  var myChart = new Chart(ctx, {
    type: 'line',
    data: {
      labels: [
        'Sunday',
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday'
      ],
      datasets: [{
        data: [
          15339,
          21345,
          18483,
          24003,
          23489,
          24092,
          12034
        ],
        lineTension: 0,
        backgroundColor: 'transparent',
        borderColor: '#007bff',
        borderWidth: 4,
        pointBackgroundColor: '#007bff'
      }]
    },
    options: {
      scales: {
        yAxes: [{
          ticks: {
            beginAtZero: false
          }
        }]
      },
      legend: {
        display: false
      }
    }
  })
}
}())


$('#collapseMesages').on('hide.bs.collapse', function () {
  console.log("hide.bs.collapse")
  sessionStorage.showMessages = 'hide'
})

$('#collapseMesages').on('show.bs.collapse', function () {
  console.log("show.bs.collapse")
  sessionStorage.showMessages = 'show'
})

console.log("set collapse", sessionStorage.showMessages)
$('#collapseMesages').collapse(sessionStorage.showMessages)

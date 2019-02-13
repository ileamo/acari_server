

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
        'пн',
        'вт',
        'ср',
        'чт',
        'пт',
        'сб',
        'вс'
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


$('#collapseMessages').on('hide.bs.collapse', function () {
  sessionStorage.showMessages = 'hide';
})

$('#collapseMessages').on('show.bs.collapse', function () {
  sessionStorage.showMessages = 'show'
})

$('#collapseMessages').collapse(sessionStorage.showMessages || 'show')

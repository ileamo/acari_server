//import $ from "jquery"
//require('jszip')(window, $);
require('datatables.net')(window, $);
require('datatables.net-bs4')(window, $);
require('datatables.net-buttons')(window, $);
require('datatables.net-buttons-bs4')(window, $);
require('datatables.net-buttons/js/buttons.html5.js')(window, $);
require('datatables.net-buttons/js/buttons.print.js')(window, $);
require('datatables.net-buttons/js/buttons.colVis.js')(window, $);
require('datatables.net-select')(window, $);
require('datatables.net-select-bs4')(window, $);


$.extend($.fn.dataTable.defaults, {
  language: {
    "processing": "Подождите...",
    "search": "Поиск:",
    "lengthMenu": "Показать _MENU_ записей",
    "info": "Записи с _START_ до _END_ из _TOTAL_ записей",
    "infoEmpty": "Записи с 0 до 0 из 0 записей",
    "infoFiltered": "(отфильтровано из _MAX_ записей)",
    "infoPostFix": "",
    "loadingRecords": "Загрузка записей...",
    "zeroRecords": "Записи отсутствуют.",
    "emptyTable": "В таблице отсутствуют данные",
    "paginate": {
      "first": "Первая",
      "previous": "Предыдущая",
      "next": "Следующая",
      "last": "Последняя"
    },
    "aria": {
      "sortAscending": ": активировать для сортировки столбца по возрастанию",
      "sortDescending": ": активировать для сортировки столбца по убыванию"
    }
  }

});

let datatable_dom =
  "<'mb-2'B>" +
  "<'row'<'col-sm-12 col-md-6'l><'col-sm-12 col-md-6'f>>" +
  "<'row'<'col-sm-12'tr>>" +
  "<'row'<'col-sm-12 col-md-5'i><'col-sm-12 col-md-7'p>>"

let datatable_dom_wo_find =
  "<'mb-2'B>" +
  "<'row'<'col-sm-12 col-md-6'l><'col-sm-12 col-md-6'>>" +
  "<'row'<'col-sm-12'tr>>" +
  "<'row'<'col-sm-12 col-md-5'i><'col-sm-12 col-md-7'p>>"

let datatatable_csv_text = '<i class="fas fa-file-csv"></i> Экспорт CSV'
let datatatable_print_text = '<i class="fas fa-print"></i> Печать'

datatable_params = {
  select: true,
  stateSave: true,
  responsive: true,
  dom: datatable_dom,
  buttons: [{
      extend: 'csv',
      text: datatatable_csv_text,
      className: 'btn btn-outline-secondary',
      exportOptions: {
        columns: ':visible:not(.not-export-col)'
      }
    },
    {
      extend: 'print',
      text: datatatable_print_text,
      autoPrint: false,
      className: 'btn btn-outline-secondary',
      exportOptions: {
        columns: ':visible:not(.not-export-col)'
      }
    },
    {
      extend: 'colvis',
      text: "Столбцы",
      className: 'btn btn-outline-secondary',
      postfixButtons: [{
          extend: 'colvisGroup',
          text: 'Показать все',
          show: ':hidden',
          className: "text-secondary"
        },
        {
          extend: 'colvisRestore',
          text: 'Восстановить',
          className: "text-secondary"
        }
      ]
    }
  ]
}

datatable_params_wo_find = Object.assign({}, datatable_params)
datatable_params_wo_find.dom = datatable_dom_wo_find

$.fn.dataTable.Buttons.defaults.dom.button.className = 'btn';

var table = $("#datatable").DataTable(datatable_params);
var table_all = $("#datatable_all").DataTable(datatable_params);

$('.buttonNext').addClass('btn btn-success');
$('.buttonPrevious').addClass('btn btn-primary');
$('.buttonFinish').addClass('btn btn-default');


if (document.getElementById("delete-selected-clients")) {
  let is_selected
  $('#delete-selected-clients').on('show.bs.modal', function(event) {
    let selected = table.rows('.selected').data()
    let num = selected.length
    if (num > 0) {
      is_selected = true
      let names = selected.map(function(x) {
        return x[1]
      }).join(', ')
      let ids = selected.map(function(x) {
        return x[0]
      }).join(',')
      $(this).find('.modal-body #delete-selected-clients-list').text(names)
      $(this).find('.modal-body #delete-selected-clients-num').text(num)
      document.getElementById('delete-selected-clients-id-list').value = ids
    } else {
      is_selected = false
      $(this).find('.modal-body #delete-selected-clients-list').text('')
    }
  })

  $('#delete-selected-clients').on('shown.bs.modal', function(event) {
    if (!is_selected) {
      $(this).modal('hide')
      setTimeout(alert, 100, 'Не выделена ни одна строка в таблице')
    }
  })
}

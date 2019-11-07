//import $ from "jquery"
//require('jszip')(window, $);
require('datatables.net-bs4')(window, $);
require('datatables.net-buttons')(window, $);
require('datatables.net-buttons/js/buttons.html5.js')(window, $);
require('datatables.net-buttons/js/buttons.print.js')(window, $);


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

let datatable_dom = "<'row'<'col-sm-12 col-md-6'l><'col-sm-12 col-md-6'f>>" +
  "<'row'<'col-sm-12'tr>>" +
  "<'row'<'col-sm-12 col-md-5'i><'col-sm-12 col-md-7'p>>" +
  "<B>"

let datatatable_csv_text = '<i class="fas fa-file-csv"></i> Экспорт CSV'
let datatatable_print_text = '<i class="fas fa-print"></i> Печать'

datatable_params = {
  stateSave: true,
  responsive: true,
  dom: datatable_dom,
  buttons: [{
      extend: 'csv',
      text: datatatable_csv_text,
    },
    {
      extend: 'print',
      text: datatatable_print_text,
      autoPrint: false
    }
  ]
}

datatable_params_not_last = {
  stateSave: true,
  responsive: true,
  dom: datatable_dom,
  buttons: [{
      extend: 'csv',
      text: datatatable_csv_text,
      exportOptions: {
        columns: ':not(:last-child)',
      }
    },
    {
      extend: 'print',
      text: datatatable_print_text,
      autoPrint: false,
      exportOptions: {
        columns: ':not(:last-child)',
      }
    }
  ]
}

var table = $("#datatable").DataTable(datatable_params_not_last);
var table_all = $("#datatable_all").DataTable(datatable_params);


$('.buttonNext').addClass('btn btn-success');
$('.buttonPrevious').addClass('btn btn-primary');
$('.buttonFinish').addClass('btn btn-default');

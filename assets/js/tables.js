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
    },
    "select": {
      "rows": {
        "_": "Выбрано записей: %d",
        "0": "",
        //"0": "Кликните по записи для выбора",
        "1": "Выбрана одна запись"
      }
    }

  }

});

let datatable_dom =
  "<'d-flex justify-content-lg-between flex-wrap mb-2'Bp>" +
  "<'d-flex justify-content-between flex-wrap'lf>" +
  "<tr>" +
  "<'d-flex justify-content-between flex-wrap'ip>"

let datatable_dom_wo_find =
  "<'d-flex justify-content-lg-between flex-wrap mb-2'Bp>" +
  "<'d-flex justify-content-start'l>" +
  "<tr>" +
  "<'d-flex justify-content-between flex-wrap'ip>"

let datatatable_csv_text = '<i class="fas fa-file-csv"></i> Экспорт CSV'
let datatatable_print_text = '<i class="fas fa-print"></i> Печать'

datatable_params = {
  select: false,
  stateSave: true,
  stateDuration: 0,
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

let select_buttons = [{
  text: 'Отметить все',
  className: 'btn btn-outline-secondary',
  action: function() {
    table_select.rows().select();
  }
}, {
  text: 'Снять отметки',
  className: 'btn btn-outline-secondary',
  action: function() {
    table_select.rows().deselect();
  }
}]

datatable_params_wo_find = Object.assign({}, datatable_params)
datatable_params_wo_find.dom = datatable_dom_wo_find

datatable_params_with_select = Object.assign({}, datatable_params)
datatable_params_with_select.select = true
datatable_params_with_select.buttons =
  select_buttons.concat(datatable_params_with_select.buttons)

$.fn.dataTable.Buttons.defaults.dom.button.className = 'btn';

let datatable_params_desc0 = Object.assign({}, datatable_params)
datatable_params_desc0.order = [
  [0, 'desc']
]


var table = $("#datatable").DataTable(datatable_params);
var table_all = $("#datatable_all").DataTable(datatable_params);
var table_desc_0 = $("#datatable_desc0").DataTable(datatable_params_desc0);
var table_select = $("#datatable-select").DataTable(datatable_params_with_select);

$('.buttonNext').addClass('btn btn-success');
$('.buttonPrevious').addClass('btn btn-primary');
$('.buttonFinish').addClass('btn btn-default');


if (document.getElementById("exec-selected-clients")) {
  let content = {
    "delete": {
      title: "Удаление клиентов",
      text: "Будут удалены следующие клиенты",
      action: "Удалить клиентов",
      confirm: "Вы уверены что хотите удалить выбранных клиентов?"
    },
    "lock": {
      title: "Блокировка клиентов",
      text: "Будут заблокированы следующие клиенты",
      action: "Заблокировать клиентов",
      confirm: "Вы уверены что хотите заблокировать выбранных клиентов?"
    },
    "unlock": {
      title: "Разлокировка клиентов",
      text: "Будут разблокированы следующие клиенты",
      action: "Разблокировать клиентов",
      confirm: "Вы уверены что хотите разблокировать выбранных клиентов?"
    },
    "class": {
      title: "Назначение класса",
      text: "Новый класс будет назначен следующим клиентам",
      action: "Назначить новый класс",
      confirm: "Вы уверены что хотите назначить новый класс выбранным клиентам?"
    },
    "groups": {
      title: "Назначение групп",
      text: "Новые группы будут назначены следующим клиентам",
      action: "Назначить новые группы",
      confirm: "Вы уверены что хотите назначить новые группы выбранным клиентам?"
    },
    "work-order": {
      title: "Задание на установку",
      text: "Будет выдано задание на установку клиентов",
      action: "Выдать задание",
      confirm: "Вы уверены что хотите выдать задание?"
    }
  }
  let is_selected

  $('#exec-selected-clients').on('show.bs.modal', function(event) {
    let data_field = $(event.relatedTarget)
    operation = data_field.data('operation')

    let selected = table_select.rows('.selected').data()
    let num = selected.length
    if (num > 0) {
      is_selected = true
      let names = selected.map(function(x) {
        return x[1]
      }).join(', ')
      let ids = selected.map(function(x) {
        return x[0]
      }).join(',')
      $(this).find('.modal-header #exec-selected-clients-title')
        .text(content[operation].title)
      $(this).find('.modal-body #exec-selected-clients-text')
        .text(content[operation].text)
      $(this).find('.modal-body #exec-selected-clients-list').text(names)
      $(this).find('.modal-body #exec-selected-clients-num').text(num)
      document.getElementById('exec-selected-clients-id-list').value = ids
      document.getElementById('exec-selected-clients-operation').value = operation
      $(this).find('.modal-body #exec-selected-clients-action')
        .text(content[operation].action)

      if (operation == "class") {
        $(this).find('.modal-body #exec-selected-clients-groups-form')
          .addClass("d-none");
        $(this).find('.modal-body #exec-selected-clients-class-form')
          .removeClass("d-none");
      } else if (operation == "groups") {
        $(this).find('.modal-body #exec-selected-clients-class-form')
          .addClass("d-none");
        $(this).find('.modal-body #exec-selected-clients-groups-form')
          .removeClass("d-none");
      }


    } else {
      is_selected = false
      $(this).find('.modal-body #exec-selected-clients-list').text('')
    }
  })

  $('#exec-selected-clients').on('shown.bs.modal', function(event) {
    if (!is_selected) {
      $(this).modal('hide')
      setTimeout(alert, 100, 'Не выделена ни одна строка в таблице')
    }
  })
}

let linkx = document.getElementById("export-templates-linkX")
if (linkx) {
  linkx.addEventListener('click', function(event) {
    // Stop the link from redirecting
    event.preventDefault();

    let selected = table_select.rows('.selected').data()
    let num = selected.length
    if (num > 0) {
      let ids = selected.map(function(x) {
        return x[0]
      }).join(',')
      // Redirect instead with JavaScript
      window.location.href = linkx.href + '?list=' + encodeURIComponent(ids)
    } else {
      alert('Не выделена ни одна строка в таблице')
    }
  }, false);
}

if (document.getElementById("client-comments")) {
  $('#client-comments').on('show.bs.modal', function(event) {
    let data_field = $(event.relatedTarget)
    $(this).find('.modal-body #client-comments-other-users').html(data_field.data('other-users'))
    document.getElementById('client-comments-user-id').value = data_field.data('user-id')
    document.getElementById('client-comments-client-id').value = data_field.data('client-id')
    document.getElementById('client-comments-comment-id').value = data_field.data('comment-id')
    document.getElementById('client-comments-content').value = data_field.data('user-comment')
  })

  let print_qr = document.getElementById("print-qr")
  if (print_qr) {
    print_qr.addEventListener('phoenix.link.click', function(e) {
      e.stopPropagation();
      let selected = table_select.rows('.selected').data()
      if (selected.length > 0) {
        let ids = selected.map(function(x) {
          return x[0]
        }).join(',')
        e.target.setAttribute("href", "/qr?clients_list=" + encodeURIComponent(ids))
      } else {
        alert('Не выделена ни одна строка в таблице')
        event.preventDefault();
      }
    }, false);
  }

}

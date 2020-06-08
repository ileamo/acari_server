// Messages
$('#collapseMessages').on('hide.bs.collapse', function() {
  localStorage.showMessages = 'hide';
})

$('#collapseMessages').on('show.bs.collapse', function() {
  localStorage.showMessages = 'show'
})

$('#collapseMessages').collapse(localStorage.showMessages || 'show')


$(function() {
  $('[data-toggle="popover"]').popover()
})

$('.popover-dismiss').popover({
  trigger: 'focus'
})

$('body').tooltip({selector: '[data-toggle="tooltip"]'});

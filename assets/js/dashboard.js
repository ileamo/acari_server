$('#collapseMessages').on('hide.bs.collapse', function() {
  sessionStorage.showMessages = 'hide';
})

$('#collapseMessages').on('show.bs.collapse', function() {
  sessionStorage.showMessages = 'show'
})

$('#collapseMessages').collapse(sessionStorage.showMessages || 'show')


$(function() {
  $('[data-toggle="popover"]').popover()
})

$('.popover-dismiss').popover({
  trigger: 'focus'
})

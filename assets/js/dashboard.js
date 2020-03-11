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

$(document)
    .one('focus.autoExpand', 'textarea.autoExpand', function(){
        var savedValue = this.value;
        this.value = '';
        this.baseScrollHeight = this.scrollHeight;
        this.value = savedValue;
    })
    .on('input.autoExpand', 'textarea.autoExpand', function(){
        var minRows = this.getAttribute('data-min-rows')|0, rows;
        this.rows = minRows;
        rows = Math.ceil((this.scrollHeight - this.baseScrollHeight) / 22);
        this.rows = minRows + rows;
    });

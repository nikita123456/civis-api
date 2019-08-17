import 'bootstrap/js/dist/tooltip';
import 'select2';

select2_form_input_ui = ->
  console.log "input"
  $('.form-select-label-group select').each ->
    if $(this).val().length != 0
      $(this).parent().find('.select2-container--default').addClass('placeholder-padding')
      $(this).parent().find('label').removeClass('d-none')
    else
      $(this).parent().find('.select2-container--default').removeClass('placeholder-padding')
      $(this).parent().find('label').addClass('d-none')
    if $(this).data("id") && $(this).data("value")
      id = $(this).data("id")
      value = $(this).data("value")
      selectedOption = $('<option selected=\'selected\'></option>').val(id).text(value) 
      $(this).append(selectedOption).trigger 'change'

$(document).on 'turbolinks:load', ->
  $('.alert').delay(3000).slideUp 1000
  $('[data-toggle="tooltip"]').tooltip()
  return

$(document).on 'turbolinks:load', ->
  fasterPreview = (uploader) ->
    if uploader.files and uploader.files[0]
      $('#profileImage').attr 'src', window.URL.createObjectURL(uploader.files[0])
    return

  $('#profileImage').click (e) ->
    $('#imageUpload').click()
    return

  $('#imageUpload').change ->
    fasterPreview this
    return

  $(window).on 'load', ->
    $ -> select2_form_input_ui()
  $('.select2').select2()
  $(document).on 'change', '.form-select-label-group select', () -> 
    if $(this).val().length != 0
      $(this).parent().find('.select2-container--default').addClass('placeholder-padding')
      $(this).parent().find('label').removeClass('d-none slidedown')
    else
      $(this).parent().find('.select2-container--default').removeClass('placeholder-padding')
      $(this).parent().find('label').addClass('d-none slideup')
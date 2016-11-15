((E, $) ->
  'use strict'

  $(document).ready ->
    $('*[data-operation-in-progress="true"]').text($('*[data-operation-in-progress]').data('disable-with')).prop('disabled', true)

) ekylibre, jQuery

pluralize = (number, unit) ->
  "#{number}#{unit}"

$ ->
  $('a[rel~=popover], .has-popover').popover()
  $('a[rel~=tooltip], .has-tooltip').tooltip()
  $('.select2').select2
    theme: 'bootstrap'

  moment.tz.setDefault 'America/New_York'
  now = moment()
  $('.time-diff').each ->
    date = moment.parseZone($(@).text())
    duration = moment.duration(now.diff(date, 'milliseconds'))
    days = parseInt(duration.asDays(), 10)
    hours = parseInt(duration.asHours(), 10) - days * 24
    minutes = parseInt(duration.asMinutes(), 10) - (days * 24 + hours) * 60

    arr = []
    arr.push pluralize(days, 'd') if days > 0
    arr.push pluralize(hours, 'h') if hours > 0
    arr.push pluralize(minutes, ' min') if minutes > 0
    arr.push 'just now' if arr.length is 0
    len = arr.length
    arr[len - 1] = "and #{arr[len - 1]}" if len > 1
    $(@).text arr.join(', ')

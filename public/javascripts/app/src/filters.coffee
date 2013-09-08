app = angular.module 'app'

app.filter 'duration', ->
  (ms) ->
    unless ms
      '0 mins'
    else
      minutes = Math.ceil(moment.duration(ms).asMinutes())
      hours = parseInt(minutes / 60, 10)
      minutes -= (60*hours)
      parts = []
      if hours  then parts.push "#{hours} hr#{if hours > 1 then 's' else ''}"
      if minutes then parts.push "#{minutes} min#{if minutes > 1 then 's' else ''}"
      parts.join ', '

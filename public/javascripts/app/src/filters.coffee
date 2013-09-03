app = angular.module 'app'

app.filter 'duration', ->
  (ms) ->
    if ms then moment.duration(ms).humanize() else '0 ms'

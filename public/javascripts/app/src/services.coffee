app = angular.module 'app'

app.service 'Frames', ($http, $location) ->
  list: (callback) ->
    $http.get('/api/frames').success callback

  get: (id, callback) ->
    $http.get("/api/frames/#{id}").success callback

  save: (frame, callback) ->
    if frame._id
      req = $http.put('/api/frames', frame)
      req.success callback
    else
      $http.post('/api/frames', frame).success (created) ->
        frame._id = created._id
        $location.path "/frames/#{created._id}"
        callback()

  remove: (id, callback) ->
    $http.delete("/api/frames/#{id}").success callback

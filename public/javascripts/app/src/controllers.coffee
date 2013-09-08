app = angular.module 'app'

app.config ($routeProvider) ->
  $routeProvider
    .when '/frames',
      controller: 'FrameCollectionController'
      templateUrl: '/templates/frames/list.html'
    .when '/frames/:id',
      controller: 'FrameController'
      templateUrl: '/templates/frames/edit.html'
    .otherwise
      redirectTo: '/frames'

DATETIME_FORMAT = 'YYYY-MM-DDTHH:mm:ss'

app.controller 'FrameController', ($scope, $routeParams, Frames) ->
  now = ->
    moment().format(DATETIME_FORMAT)

  $scope.startNewProject = ->
    newProject =
      name: 'A new project...'
      tasks: []
    $scope.frame.projects or= []
    $scope.frame.projects.unshift newProject
    $scope.startNewTask newProject

  $scope.startNewTask = (project) ->
    newTask =
      name: "A new task..."
      entries: []
    project.tasks.unshift newTask
    $scope.playPause newTask

  pauseActiveTask = ->
    $scope.activeTask.entries.unshift
      start: $scope.activeEntry.start
      end: now()

  startNewActiveTask = (task) ->
    $scope.activeTask = task
    $scope.activeEntry =
      start: now()

  $scope.playPause = (task) ->
    if $scope.activeEntry
      pauseActiveTask()
      if $scope.isActive(task)
        $scope.activeTask = null
        $scope.activeEntry = null
      else
        startNewActiveTask(task)
    else
      startNewActiveTask(task)

  $scope.isActive = (task) ->
    task is $scope.activeTask

  $scope.canRemoveTasks = (project) ->
    project.tasks.length > 1

  $scope.timeSpent = (task) ->
    ms = 0
    for entry in task.entries when entry.end and entry.start
      ms += (new Date(entry.end) - new Date(entry.start))
    ms

  $scope.cloneProject = (project, index) ->
    cloneProject =
      name: project.name
      tasks: []
    for task in project.tasks
      cloneProject.tasks.push
        name: task.name
        entries: []
    $scope.frame.projects.splice(index, 0, cloneProject)

  $scope.cloneTask = (task, project, index) ->
    cloneTask =
      name: task.name
      entries: []
    project.tasks.splice(index, 0, cloneTask)

  $scope.removeProjectAt = (index) ->
    $scope.frame.projects.splice(index, 1)

  $scope.removeTaskAt = (index, project) ->
    project.tasks.splice(index, 1)

  $scope.removeEntryAt = (index, task) ->
    task.entries.splice(index, 1)

  $scope.clearEntries = (task) ->
    task.entries.splice(0)

  $scope.editTask = (task) ->
    $scope.editedTask = task
    $('.modal').modal('toggle')

  $scope.addEntry = (task) ->
    task.entries.unshift
      start: now()
      end: moment().add(1,'hour').format(DATETIME_FORMAT)

  $scope.saveFrame = ->
    $scope.saving = yes
    Frames.save $scope.frame, ->
      $scope.saving = no

  $scope.cloneFrame = ->
    cloneFrame =
      name: $scope.frame.name + '*'
      projects: []
    for project in $scope.frame.projects
      cloneProject =
        name: project.name
        tasks: []
      for task in project.tasks
        cloneProject.tasks.push
          name: task.name
          entries: []
      cloneFrame.projects.push cloneProject
    $scope.frame = cloneFrame
    $scope.saveFrame()

  $scope.frame =
    name: 'time'
    projects: []

  Frames.get $routeParams.id, (frame) ->
    $scope.frame = frame if frame

app.controller 'SummaryController', ($scope) ->
  groupByDate = (entries) ->
    _.groupBy entries, (entry) -> moment(entry.start, DATETIME_FORMAT).format('YYYY-MM-DD')

  roundTo15minutes = (hours) ->
    whole = Math.floor(hours)
    partial = hours - whole
    if 0 < partial < 0.125
      partial = 0
    else if 0.125 <= partial < 0.375
      partial = 0.25
    else if 0.375 <= partial < 0.625
      partial = 0.5
    else if 0.625 <= partial < 0.875
      partial = 0.75
    else if 0.875 <= partial < 1
      partial = 1
    whole + partial

  calculateTable = ->
    allTasks = []
    allDates = []
    for project in $scope.frame.projects
      for task in project.tasks
        entries = groupByDate(_.select(task.entries, (entry) -> entry.start and entry.end))
        allDates.push date for date in _.keys(entries)
        allTasks.push
          name: task.name
          entriesByDate: entries

    $scope.allDates = (_.uniq allDates).sort()
    $scope.allTasks = allTasks

  $scope.timeSpentOnDateDoingTask = (date, task) ->
    entries = task.entriesByDate[date]
    ms = 0
    sum = 0
    if entries?.length
      for entry in entries when entry.end and entry.start
        ms += new Date(entry.end) - new Date(entry.start)
        sum = roundTo15minutes(moment.duration(ms).asHours())
        entries['sum'] = sum
    sum

  $scope.timeSpentOnDate = (date) ->
    sum = 0
    for task in $scope.allTasks
      entries = task.entriesByDate[date]
      sum += entries['sum'] if entries?.length
    sum

  $scope.timeSpentDoingTask = (task) ->
    sum = 0
    if task.entriesByDate
      for own date, entries of task.entriesByDate
        sum += entries['sum'] if entries?
    sum

  $scope.timeSpent = ->
    sum = 0
    for date in $scope.allDates
      sum += $scope.timeSpentOnDate(date)
    sum

  $scope.$watch('frame.projects', calculateTable, true)

app.controller 'FrameCollectionController', ($scope, $location, Frames) ->
  $scope.createNew = ->
    newFrame =
      name: moment().format('YYYY[\'s] Wo [week]')
      projects: []
    Frames.save newFrame, (created) ->
      $scope.editFrame newFrame

  $scope.editFrame = (frame) ->
    $location.path "/frames/#{frame._id}"

  $scope.removeFrameAt = (index) ->
    removedFrame = $scope.frames[index]
    Frames.remove removedFrame._id, ->
      $scope.frames.splice(index, 1)

  $scope.nbOfTasks = (frame) ->
    count = 0
    count += project.tasks.length for project in frame.projects
    count

  $scope.recordedTimeSpan = (frame) ->
    ms = 0
    for project in frame.projects
      for task in project.tasks when task.entries.length
        for entry in task.entries when entry.start and entry.end
          ms += new Date(entry.end) - new Date(entry.start)
    ms

  Frames.list (frames) ->
    $scope.frames = frames

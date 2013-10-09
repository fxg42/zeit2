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

  $scope.timeSpent = (task) ->
    ms = 0
    for entry in task.entries when entry.end and entry.start
      ms += (new Date(entry.end) - new Date(entry.start))
    ms

  $scope.timeSpentOnProject = (project) ->
    ms = 0
    for task in project.tasks
      ms += $scope.timeSpent task
    ms

  $scope.cloneProject = (project, index) ->
    cloneProject =
      name: "#{project.name} (copy)"
      tasks: []
    for task in project.tasks
      cloneProject.tasks.push
        name: task.name
        entries: []
    $scope.frame.projects.splice(index+1, 0, cloneProject)

  $scope.cloneTask = (task, project, index) ->
    cloneTask =
      name: "#{task.name} (copy)"
      entries: []
    project.tasks.splice(index + 1, 0, cloneTask)

  $scope.mergeProjects = (projectIndex) ->
    $scope.mergeableProjects = []
    for project, index in $scope.frame.projects
      $scope.mergeableProjects.push
        name: project.name
        duration: $scope.timeSpentOnProject project
        index: index
        mergeSrc: projectIndex is index
        mergeDst: projectIndex is index
    $('#merge-projects-modal').modal('toggle')

  $scope.mergeTasks = (project, taskIndex) ->
    $scope.mergeableProject = project
    $scope.mergeableTasks = []
    for task, index in project.tasks
      $scope.mergeableTasks.push
        name: task.name
        duration: $scope.timeSpent(task)
        index: index
        mergeSrc: taskIndex is index
        mergeDst: taskIndex is index
    $('#merge-tasks-modal').modal('toggle')

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
    $('#edit-modal').modal('toggle')

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
    if frame
      $scope.frame = frame
      $scope.$watch('frame', $scope.saveFrame, yes)

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
    allProjects = (project for project in $scope.frame.projects when project.tasks.length)
    for project in allProjects
      for task in project.tasks
        entries = groupByDate(_.select(task.entries, (entry) -> entry.start and entry.end))
        allDates.push date for date in _.keys(entries)
        allTasks.push
          name: task.name
          entriesByDate: entries

    $scope.allDates = (_.uniq allDates).sort()
    $scope.allTasks = allTasks
    $scope.allProjects = allProjects

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

app.controller 'MergeProjectsController', ($scope) ->
  $scope.toggleSrc = (project) ->
    project.mergeSrc = not project.mergeSrc

  $scope.toggleDst = (project) ->
    if project.mergeDst
      project.mergeDst = no
    else
      each.mergeDst = no for each in $scope.mergeableProjects
      project.mergeDst = not project.mergeDst

  $scope.canMerge = ->
    src = no
    dst = no
    if $scope.mergeableProjects?.length
      for project in $scope.mergeableProjects
        src = yes if project.mergeSrc
        dst = yes if project.mergeDst
    src and dst

  $scope.merge = ->
    if $scope.canMerge()
      mergeDst = (project for project in $scope.mergeableProjects when project.mergeDst)[0]
      dst = $scope.frame.projects[mergeDst.index]
      for mergeSrc in $scope.mergeableProjects when mergeSrc.mergeSrc and mergeSrc.index isnt mergeDst.index
        src = $scope.frame.projects[mergeSrc.index]
        dst.tasks = dst.tasks.concat src.tasks
        src.shouldRemove = yes
      $scope.frame.projects = (project for project in $scope.frame.projects when not project.shouldRemove)
    $('#merge-projects-modal').modal('hide')

app.controller 'MergeTasksController', ($scope) ->
  $scope.toggleSrc = (task) ->
    task.mergeSrc = not task.mergeSrc

  $scope.toggleDst = (task) ->
    if task.mergeDst
      task.mergeDst = no
    else
      each.mergeDst = no for each in $scope.mergeableTasks
      task.mergeDst = not task.mergeDst

  $scope.canMerge = ->
    src = no
    dst = no
    if $scope.mergeableTasks?.length
      for task in $scope.mergeableTasks
        src = yes if task.mergeSrc
        dst = yes if task.mergeDst
    src and dst

  $scope.merge = ->
    if $scope.canMerge()
      mergeDst = (task for task in $scope.mergeableTasks when task.mergeDst)[0]
      dst = $scope.mergeableProject.tasks[mergeDst.index]
      for mergeSrc in $scope.mergeableTasks when mergeSrc.mergeSrc and mergeSrc.index isnt mergeDst.index
        src = $scope.mergeableProject.tasks[mergeSrc.index]
        dst.entries = dst.entries.concat src.entries
        src.shouldRemove = yes
      $scope.mergeableProject.tasks = (task for task in $scope.mergeableProject.tasks when not task.shouldRemove)
    $('#merge-tasks-modal').modal('hide')

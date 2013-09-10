app = angular.module 'app'

app.directive 'confirmation', ->
  restrict: 'A'
  scope:
    yep: '&'
  link: (scope, el, attrs) ->
    el.popover
      html: yes
      content: "
        <div class='btn-group confirmation'>
          <button class='btn btn-success'><i class='icon-thumbs-up'/> yep</button>
          <button class='btn btn-warning'><i class='icon-thumbs-down'/> nope</button>
        </div>
      "
    el.bind 'click', (ev) ->
      el.next('.popover').find('button.btn-success').on 'click', (ev) ->
        scope.$apply -> scope.yep()
        el.popover('hide')
        ev.stopPropagation()
      el.next('.popover').find('button.btn-warning').on 'click', (ev) ->
        el.popover('hide')
        ev.stopPropagation()
      ev.stopPropagation()

app.directive 'contenteditable', ->
  restrict: 'A'
  require: '?ngModel'
  link: (scope, el, attrs, ngModel) ->
    ngModel.$render = ->
      el.html ngModel.$viewValue

    el.bind 'keyup blur paste', ->
      scope.$apply ->
        ngModel.$setViewValue el.html()

    el.bind 'click', (e) ->
      e.stopPropagation()

app.directive 'sortable', ->
  restrict: 'A'
  require: '?ngModel'
  link: (scope, el, attrs, ngModel) ->
    startIndex = -1
    el.sortable
      handle: attrs.sortableHandle
      tolerance: 'pointer'
      start: (ev, ui) ->
        startIndex = $(ui.item).index()
      stop: (ev, ui) ->
        stopIndex = $(ui.item).index()
        if startIndex isnt stopIndex
          scope.$apply ->
            sortedItem = ngModel.$modelValue.splice(startIndex, 1)[0]
            ngModel.$modelValue.splice(stopIndex, 0, sortedItem)

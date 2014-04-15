RefactoringView = require './RefactoringView'


module.exports =
new class Main

  activate: (state) ->
    @isHighlight = false

    @refactoringViews = []
    atom.workspaceView.eachEditorView @onEditorViewCreated

    atom.workspaceView.command 'coffee-refactor:toggle-highlight', (e) =>
      @isHighlight = !@isHighlight
      @callViews e, 'highlight', @isHighlight
    atom.workspaceView.command 'coffee-refactor:rename', (e) =>
      @callActiveViews e, 'rename'
    atom.workspaceView.command 'coffee-refactor:done', (e) =>
      @callActiveViews e, 'done'

  deactivate: ->
    for view in @refactoringViews
      view.destruct()

  serialize: ->
    console.log 'serialize'


  callViews: (e, methodName, args...) ->
    # isCalled = false
    for view, i in @refactoringViews
      view[methodName].apply view, args

    # unless isCalled
    #   e.abortKeyBinding()

  callActiveViews: (e, methodName, args...) ->
    activePaneItem = atom.workspaceView.getActivePaneItem()
    isCalled = false
    for view in @refactoringViews
      if view.isSameEditor activePaneItem
        isCalled or= view[methodName].apply view, args

    unless isCalled
      e.abortKeyBinding()


  onEditorViewCreated: (editorView) =>
    refactoringView = new RefactoringView editorView
    editorView.getEditor().on 'destroyed', =>
      @onEditorViewDestroyed refactoringView
    refactoringView.highlight @isHighlight
    @refactoringViews.push refactoringView

  onEditorViewDestroyed: (refactoringView) ->
    refactoringView.destruct()
    index = @refactoringViews.indexOf refactoringView
    return if index is -1
    @refactoringViews.splice index, 1
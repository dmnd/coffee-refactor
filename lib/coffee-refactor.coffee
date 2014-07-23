Ripper = require './ripper'
NotificationView = require './notification-view'
{ packages: packageManager } = atom


module.exports =
  activate: ->
    console.log 'coffee-refactor:activate'
    atom.workspace.emit 'coffee-refactor-became-active'
    return if 'refactor' in packageManager.getAvailablePackageNames() and
              !packageManager.isPackageDisabled 'refactor'
    new NotificationView
  deactivate: ->
  serialize: ->
  Ripper: Ripper

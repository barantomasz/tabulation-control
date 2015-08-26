TabulationControlStatusElement = require './status-element'

module.exports =
  deactivate: ->
    @statusElement?.remove()

  consumeStatusBar: (statusBar) ->
    @statusElement = new TabulationControlStatusElement()
    @statusElement.init(statusBar)

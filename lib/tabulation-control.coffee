# coffeelint: disable=no_tabs

TabulationControlStatusElement = require './tabulation-control-status-element'

module.exports =
  deactivate: ->
    @statusElement?.remove()

  consumeStatusBar: (statusBar) ->
    @statusElement = new TabulationControlStatusElement()
    @statusElement.init(statusBar)

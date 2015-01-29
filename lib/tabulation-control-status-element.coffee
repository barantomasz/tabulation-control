# coffeelint: disable=no_tabs

_ = require 'underscore-plus'
{$, View} = require 'atom-space-pen-views'
TabulationControlStatusView = require './tabulation-control-status-view'

class TabulationControlStatusElement extends HTMLElement
  attached: false

  init: (statusBar) ->
    statusBar.addRightTile(item: this, priority: 100)
    @model = new TabulationControlStatusView(this)

  createdCallback: ->
    @setAttribute 'class', 'inline-block'
    @tabulationStatus = $(document.createElement('span'))
    @appendChild @tabulationStatus.get()[0]

    this

  attachedCallback: ->
    @attached = true

  detachedCallback: ->
    @detached = true

  getModel: ->
    @model

  setText: (text) ->
    @tabulationStatus.text(text)

  clear: ->
    @setText('')

for item in ['t', 1, 2, 3, 4, 6, 8]
  createCallback = (cb_command, cb_item, cb) ->
    callback = {}
    callback[cb_command] = (event) ->
      @getModel()[cb](cb_item)
    callback

  command = "tabulation-control:convert_#{item}"
  atom.commands.add 'tabulation-control-status', createCallback(command, item, 'processConvertCommand')

  if item != 't'
    command = "tabulation-control:tablength_#{item}"
    atom.commands.add 'tabulation-control-status', createCallback(command, item, 'processTabLengthCommand')

module.exports = TabulationControlStatusElement = document.registerElement('tabulation-control-status', prototype: TabulationControlStatusElement.prototype)

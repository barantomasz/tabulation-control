_ = require 'underscore-plus'
{$, View} = require 'atom-space-pen-views'

module.exports =
class TabulationControlStatusView extends View
  activeTextEditor: undefined
  contextMenuAttached: false

  constructor: (@element) ->
    super

  initialize: ->
    @setUpSubscriptions()

  setUpSubscriptions: ->
    atom.workspace.observeActivePaneItem (activePaneItem) =>
      @updateStatusBar()
    atom.workspace.observeTextEditors (textEditor) =>
      @updateStatusBar()
      textEditor.onDidTokenize =>
        @updateStatusBar()
    @updateStatusBar()

    @element.addEventListener 'click', (event) ->
      # Only show the context menu if we have an active editor
      activeTextEditor = atom.workspace.getActiveTextEditor()
      if activeTextEditor?
        # TODO(driskell): This is not in the API... But I like this feature
        # Use a selectlistview?
        atom.contextMenu.showForEvent(event)

  updateContextMenu: (newContextMenuItems) ->
    if @contextMenuAttached
      @contextMenuItems.length = 0
      @contextMenuItems.push item for item in newContextMenuItems
    else
      atom.contextMenu.add 'tabulation-control-status': newContextMenuItems
      @contextMenuItems = newContextMenuItems
      @contextMenuAttached = true

  updateStatusBar: ->
    @activeTextEditor = atom.workspace.getActiveTextEditor()
    unless @activeTextEditor?
      @element.hide()
      return

    # Grab the invisible characters
    invisibles = atom.config.get('editor.invisibles', scope: @activeTextEditor.getRootScopeDescriptor())

    # Grab current editor configuration
    softTabs = @activeTextEditor.getSoftTabs()
    tabLength = @activeTextEditor.getTabLength()
    if softTabs
      indentType = _.multiplyString(invisibles.space, tabLength)
    else
      indentType = invisibles.tab

    # Create the context menu
    generateSubMenu = (type) ->
      for item in ['t', 1, 2, 3, 4, 6, 8]
        if item == 't'
          if indentType == invisibles.tab
            continue
          label = "Hard tab [ #{invisibles.tab} ]"
        else if softTabs and item == tabLength
          continue
        else
          label = "#{item} spaces [ #{_.multiplyString(invisibles.space, item)} ]"

        {label: label, command: "tabulation-control:#{type}_#{item}"}

    newContextMenuItems = [
      {
        label: 'Convert Indentation'
        submenu: generateSubMenu('convert')
      },
      {
        label: 'Indentation Width'
        submenu:
          for item in [1, 2, 3, 4, 6, 8]
            if item == tabLength
              continue
            {label: "#{item} spaces [ #{_.multiplyString(invisibles.space, item)} ]", command: "tabulation-control:tablength_#{item}"}
      }
    ]

    @updateContextMenu(newContextMenuItems)

    # The square brackets here make the click area bigger, without them it can
    # become hard to click the text to get the context menu
    # With square brackets it is also then consistent with the context menu
    # items which also have square brackets
    @element.setText("[ #{indentType} ]")

    @element.show()

  processConvertCommand: (size) ->
    return unless @activeTextEditor?

    bufferRange = [[0, 0], [@activeTextEditor.getLineCount(), 0]]

    if @activeTextEditor.getSoftTabs()
      oldTabLength = @activeTextEditor.getTabLength()
      return if size == oldTabLength

      @activeTextEditor.transact =>
        @activeTextEditor.scanInBufferRange new RegExp("^(?: {#{oldTabLength}})+", 'gm'), bufferRange, ({replace, matchText}) ->
          if size == 't'
            replace(_.multiplyString("\t", matchText.length / oldTabLength))
          else
            replace(_.multiplyString(' ', (matchText.length / oldTabLength) * size))
    else
      return if size == 't'

      @activeTextEditor.transact =>
        @activeTextEditor.scanInBufferRange /^\t+/gm, bufferRange, ({replace, matchText}) ->
          replace(_.multiplyString(' ', matchText.length * size))

    if size == 't'
      @activeTextEditor.setSoftTabs(false)
      @activeTextEditor.setTabLength(@activeTextEditor.getTabLength())
    else
      @activeTextEditor.setSoftTabs(true)
      @activeTextEditor.setTabLength(size)

    @updateStatusBar()

  processTabLengthCommand: (size) ->
    return unless @activeTextEditor?

    @activeTextEditor.setTabLength(size)

    @updateStatusBar()

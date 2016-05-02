class @LabelManager
  constructor: (opts = {}) ->
    # Defaults
    {
      @togglePriorityButton = $('.js-toggle-priority')
      @prioritizedLabels = $('.js-prioritized-labels')
      @otherLabels = $('.js-other-labels')
    } = opts

    @prioritizedLabels.sortable()

    @bindEvents()

  bindEvents: ->
    @togglePriorityButton.on 'click', @, @onTogglePriorityClick

  onTogglePriorityClick: (e) ->
    e.preventDefault()
    _this = e.data
    $btn = $(e.currentTarget)
    $label = $("##{$btn.data('domId')}")
    action = if $btn.parents('.js-prioritized-labels').length then 'remove' else 'add'
    _this.toggleLabelPriority($label, action)

  toggleLabelPriority: ($label, action) ->
    _this = @
    url = $label.find('.js-toggle-priority').data 'url'

    # Optimistic update
    $target = if action is 'remove' then @otherLabels else @prioritizedLabels
    $label.detach().appendTo($target)

    xhr = $.post url

    # If request fails, put label back to Other labels group
    xhr.fail ->
      $label.detach().appendTo(_this.otherLabels)

      # Show a message
      new Flash('Unable to prioritize this label at this time' , 'alert')

  removeLabelFromPriority: ($label) ->
    $label.detach().appendTo(@otherLabels)

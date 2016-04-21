class CiBuild
  @interval: null

  constructor: (@build_url, @build_status) ->
    clearInterval(CiBuild.interval)

    if $('#build-trace').length
      @getBuildTrace()
      @initScrollButtonAffix()

    if @build_status is "running" or @build_status is "pending"
      #
      # Bind autoscroll button to follow build output
      #
      $('#autoscroll-button').on 'click', ->
        state = $(this).data("state")
        if "enabled" is state
          $(this).data "state", "disabled"
          $(this).text "enable autoscroll"
        else
          $(this).data "state", "enabled"
          $(this).text "disable autoscroll"

      #
      # Check for new build output if user still watching build page
      # Only valid for runnig build when output changes during time
      #
      CiBuild.interval = setInterval =>
        if window.location.href.split("#").first() is @build_url
          @getBuildTrace()
      , 4000

  getBuildTrace: ->
    $.ajax
      url: @build_url
      dataType: "json"
      beforeSend: ->
        if $('.js-build-loading').length is 0
          $('#build-trace').append '<i class="fa fa-refresh fa-spin js-build-loading"/>'
      success: (build) =>
        $('#build-trace .bash').html build.trace_html

        if build.status is "running"
          @checkAutoscroll()
        else if build.status isnt "pending"
          $('.js-build-loading').remove()

        if build.status isnt @build_status
          Turbolinks.visit @build_url

  checkAutoscroll: ->
    $("html,body").scrollTop $("#build-trace").height()  if "enabled" is $("#autoscroll-button").data("state")

  initScrollButtonAffix: ->
    $buildScroll = $('#js-build-scroll')
    $body = $('body')
    $buildTrace = $('#build-trace')

    $buildScroll.affix(
      offset:
        bottom: ->
          $body.outerHeight() - ($buildTrace.outerHeight() + $buildTrace.offset().top)
    )

@CiBuild = CiBuild

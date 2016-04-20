class CiBuild
  @interval: null

  constructor: (@build_url, build_status) ->
    clearInterval(CiBuild.interval)

    $('.right-sidebar').niceScroll()

    @getBuildTrace()
    @initScrollButtonAffix()

    if build_status == "running" || build_status == "pending"
      #
      # Bind autoscroll button to follow build output
      #
      $("#autoscroll-button").bind "click", ->
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
          $('#build-trace code').append '<i class="fa fa-refresh fa-spin js-build-loading"/>'
      success: (build) =>
        $('#build-trace code').prepend build.trace_html

        if build.status == "running"
          @checkAutoscroll()
        else
          $('.js-build-loading').remove()

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

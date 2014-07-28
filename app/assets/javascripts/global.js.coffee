$(document).ready ->
  $(this).trigger("page:load")
  document.cookie = "timezone=#{jstz.determine_timezone().timezone.olson_tz}; path=/"

  $.get("/contests/ongoing.json", (e) ->
    dispatcher = new WebSocketRails("#{window.location.host}/websocket");
    channel = dispatcher.subscribe("announcements")
    e.forEach( (contest) ->
      channel.bind("#{contest.id}", (message) ->
        alert("Announcement for #{message.contest.title}!")
        )
      )
  )

$(document).on "page:fetch", ->
  $(".spinner-container").removeClass("hidden")
  $(".spinner-container").spin()

$(document).on "page:receive", ->
  $(".spinner-container").addClass("hidden")
  $(".spinner-container").spin(false)

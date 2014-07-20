$(document).ready ->
  $("body").on "keypress", "#addGroupInput", (e) ->
    $("#addGroupInput").val $("#addGroupInput").val().toLowerCase().replace(" ", "-")
    if e.which is 13
      e.preventDefault()
      $(".addGroupInput").trigger "click"
    return

  $("body").on "click", ".addGroupInput", ->
    $.ajax
      type: "POST"
      url: "/admin/settings/create_user_group"
      data: "key=" + $("#addGroupInput").val()
      dataType: "html"
      success: (data) ->
        $(".userGroupOptions").append data
        $("#addGroupInput").val ""
        return

    return

  $("body").on "click", ".remove-user-group", (e) ->
    e.preventDefault()
    $(this).closest(".form-group").remove()  if confirm(I18n.t('javascript.settings.are_you_sure'))
    return

  return

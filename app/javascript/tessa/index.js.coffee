window.WCC ||= {}
$ = window.jQuery

Dropzone.autoDiscover = off

class window.WCC.Dropzone extends window.Dropzone

  uploadFile: (file) ->
    xhr = new XMLHttpRequest
    file.xhr = xhr

    # Set in our custom accept method
    xhr.open file.uploadMethod, file.uploadURL, true

    response = null

    handleError = =>
      @_errorProcessing [file], response || @options.dictResponseError.replace("{{statusCode}}", xhr.status), xhr

    updateProgress = (e) =>
      if e?
        progress = 100 * e.loaded / e.total

        file.upload =
          progress: progress
          total: e.total
          bytesSent: e.loaded
      else
        # Called when the file finished uploading

        allFilesFinished = yes

        progress = 100

        allFilesFinished = no unless file.upload.progress == 100 and file.upload.bytesSent == file.upload.total
        file.upload.progress = progress
        file.upload.bytesSent = file.upload.total

        # Nothing to do, all files already at 100%
        return if allFilesFinished

      @emit "uploadprogress", file, progress, file.upload.bytesSent

    xhr.onload = (e) =>
      return if file.status == WCC.Dropzone.CANCELED
      return unless xhr.readyState is 4

      response = xhr.responseText

      if xhr.getResponseHeader("content-type") and ~xhr.getResponseHeader("content-type").indexOf "application/json"
        try
          response = JSON.parse response
        catch e
          response = "Invalid JSON response from server."

      updateProgress()

      unless 200 <= xhr.status < 300
        handleError()
      else
        @_finished [file], response, e

    xhr.onerror = =>
      return if file.status == WCC.Dropzone.CANCELED
      handleError()

    # Some browsers do not have the .upload property
    progressObj = xhr.upload ? xhr
    progressObj.onprogress = updateProgress

    headers =
      "Accept": "application/json",
      "Cache-Control": "no-cache",
      "X-Requested-With": "XMLHttpRequest",

    extend headers, @options.headers if @options.headers

    xhr.setRequestHeader headerName, headerValue for headerName, headerValue of headers

    @emit "sending", file, xhr

    xhr.send file

  uploadFiles: (files) ->
    @uploadFile(file) for file in files

WCC.Dropzone.uploadPendingWarning =
  "File uploads have not yet completed. If you submit the form now they will
  not be saved. Are you sure you want to continue?"

WCC.Dropzone.prototype.defaultOptions.url = "UNUSED"

WCC.Dropzone.prototype.defaultOptions.dictDefaultMessage = "Drop files or click to upload."

WCC.Dropzone.prototype.defaultOptions.accept = (file, done) ->
  dz = $(file._removeLink).closest('.tessa-upload').first()
  tessaParams = dz.data('tessa-params') or {}

  postData =
    name: file.name
    size: file.size
    mime_type: file.type

  postData = $.extend postData, tessaParams

  $.ajax '/tessa/uploads',
    type: 'POST',
    data: postData,
    success: (response) ->
      file.uploadURL = response.upload_url
      file.uploadMethod = response.upload_method
      file.assetID = response.asset_id
      done()
    error: (response) ->
      done("Failed to initiate the upload process!")

window.WCC.tessaInit = (sel) ->
  sel = sel || 'form:has(.tessa-upload)'
  $(sel).each (i, form) ->
    $form = $(form)
    $form.bind 'submit', (event) ->
      safeToSubmit = true
      $form.find('.tessa-upload').each (j, dropzoneElement) ->
        $(dropzoneElement.dropzone.files).each (k, file) ->
          if file.status? and (file.status != WCC.Dropzone.SUCCESS)
            safeToSubmit = false
      if not safeToSubmit and not confirm(WCC.Dropzone.uploadPendingWarning)
        return false

  $('.tessa-upload', sel).each (i, item) ->
    $item = $(item)
    args =
      maxFiles: 1
      addRemoveLinks: true

    $.extend args, $item.data("dropzone-options")
    args.maxFiles = null if $item.hasClass("multiple")
    inputPrefix = $item.data("asset-field-prefix")

    dropzone = new WCC.Dropzone item, args

    $item.find('input[type="hidden"]').each (j, input) ->
      $input = $(input)
      mockFile = $input.data("meta")
      mockFile.accepted = true
      dropzone.options.addedfile.call(dropzone, mockFile)
      dropzone.options.thumbnail.call(dropzone, mockFile, mockFile.url)
      dropzone.emit("complete", mockFile)
      dropzone.files.push mockFile

    updateAction = (file) ->
      return unless file.assetID?
      inputID = "#tessa_asset_action_#{file.assetID}"
      actionInput = $(inputID)
      unless actionInput.length
        actionInput = $('<input type="hidden">')
          .attr
            id: inputID
            name: "#{inputPrefix}[#{file.assetID}][action]"
          .appendTo item

      actionInput.val file.action

    dropzone.on 'success', (file) ->
      file.action = "add"
      updateAction(file)

    dropzone.on 'removedfile', (file) ->
      file.action = "remove"
      updateAction(file)


$ ->
  window.WCC.tessaInit()

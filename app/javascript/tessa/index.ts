import type Dropzone from 'dropzone'
import {FileChecksum} from '../activestorage/file_checksum'

declare global {
  interface Window {
    WCC: any,
    jQuery: any,
    Dropzone: typeof Dropzone,
  }
}

window.WCC ||= {}
const $ = window.jQuery

window.Dropzone.autoDiscover = false

interface WCCDropzoneFile extends Dropzone.DropzoneFile {
  uploadURL: string,
  uploadMethod: string,
  uploadHeaders: Record<string, string>,
  assetID: string,
}

const BaseDropzone = window.Dropzone
class WCCDropzone extends BaseDropzone {

  uploadFile(file: WCCDropzoneFile): void {
    console.log('uploadFile', file)
    const xhr = new XMLHttpRequest()
    file.xhr = xhr

    xhr.open(file.uploadMethod, file.uploadURL, true)
    let response: any = null

    const handleError = () => {
      (this as any)._errorProcessing([file], response || this.options.dictResponseError?.replace("{{statusCode}}", xhr.status.toString()), xhr)
    }

    const updateProgress = (e?: any) => {
      let progress: number
      if (e) {
        progress = 100 * e.loaded / e.total

        file.upload = {
          ...file.upload,
          progress: progress,
          total: e.total,
          bytesSent: e.loaded
        } as Dropzone.DropzoneFileUpload
      } else {
        // Called when the file finished uploading
        progress = 100
        let allFilesFinished = false
        if (file.upload!.progress == 100 && file.upload!.bytesSent == file.upload!.total) {
          allFilesFinished = true
        }
        file.upload!.progress = progress
        file.upload!.bytesSent = file.upload?.total!

        // Nothing to do, all files already at 100%
        if (allFilesFinished) { return }
      }

      this.emit("uploadprogress", file, progress, file.upload!.bytesSent)
    }

    xhr.onload = (e) => {
      if (file.status == WCCDropzone.CANCELED) { return }
      if (xhr.readyState != 4) {return }

      response = xhr.responseText

      if (xhr.getResponseHeader("content-type") &&
          xhr.getResponseHeader("content-type")!.indexOf("application/json") >= 0) {
        try {
          response = JSON.parse(response)
        } catch(e) {
          response = "Invalid JSON response from server."
        }
      }

      updateProgress()

      if (xhr.status < 200 || xhr.status >= 300)
        handleError()
      else {
        (this as any)._finished([file], response, e)
      }
    }

    xhr.onerror = () => {
      if (file.status == WCCDropzone.CANCELED) { return }
      handleError()
    }

    // Some browsers do not have the .upload property
    let progressObj = xhr.upload ?? xhr
    progressObj.onprogress = updateProgress

    let headers = {
      "Accept": "application/json",
      "Cache-Control": "no-cache",
      "X-Requested-With": "XMLHttpRequest",
    }

    if (this.options.headers) { Object.assign(headers, this.options.headers) }
    if (file.uploadHeaders) { Object.assign(headers, file.uploadHeaders) }

    for (let [headerName, headerValue] of Object.entries(headers)) {
      xhr.setRequestHeader(headerName, headerValue)
    }

    this.emit("sending", file, xhr)

    xhr.send(file)
  }

  uploadFiles(files: WCCDropzoneFile[]): void {
    for (const file of files) {
      this.uploadFile(file as WCCDropzoneFile)
    }
  }
}

function tessaInit() {
  $('.tessa-upload').each(function(i: number, item: HTMLElement) {
    const $item = $(item)
    const options: Dropzone.DropzoneOptions = {
      maxFiles: 1,
      addRemoveLinks: true,
      url: 'UNUSED',
      dictDefaultMessage: 'Drop files or click to upload.',
      accept: accept,
      ...$item.data("dropzone-options")
    }

    if ($item.hasClass("multiple")) { options.maxFiles = undefined }

    const dropzone = new WCCDropzone(item, options)
  })
}

/**
 * Accepts a file upload from Dropzone, and creates an ActiveStorage blob via the Tessa::RackUploadProxy.
 *
 * Upon successfully creating the blob, retrieves a signed upload URL for direct upload.  The
 * signed URL is attached to the File object which is then passed to "uploadFile".
 *
 * @param file Binary file data uploaded by the user
 * @param done Callback when file is accepted or rejected by the Tessa::RackUploadProxy
 */
function accept(file: WCCDropzoneFile, done: (error?: string | Error) => void) {
  const postData: Record<string, string | number | undefined> = {
    name: file.name,
    size: file.size,
    mime_type: file.type
  }

  FileChecksum.create(file, (error, checksum) => {
    if (error) {
      return done(error)
    }

    postData['checksum'] = checksum

    $.ajax('/tessa/uploads', {
      type: 'POST',
      data: postData,
      success: (response: Record<string, any>) => {
        file.uploadURL = response.upload_url
        file.uploadMethod = response.upload_method
        file.uploadHeaders = response.upload_headers
        file.assetID = response.asset_id
        done()
      },
      error: (_response: any) => {
        done("Failed to initiate the upload process!")
      }
    })

  })
}

$(tessaInit)

// WCC.Dropzone.uploadPendingWarning =
//   "File uploads have not yet completed. If you submit the form now they will
//   not be saved. Are you sure you want to continue?"

// WCC.Dropzone.prototype.defaultOptions.accept = (file, done) ->
//   dz = $(file._removeLink).closest('.tessa-upload').first()
//   tessaParams = dz.data('tessa-params') or {}

//   postData =
//     name: file.name
//     size: file.size
//     mime_type: file.type

//   postData = $.extend postData, tessaParams

//   FileChecksum.create file, (error, checksum) ->
//     return done(error) if error

//     postData['checksum'] = checksum

//     $.ajax '/tessa/uploads',
//       type: 'POST',
//       data: postData,
//       success: (response) ->
//         file.uploadURL = response.upload_url
//         file.uploadMethod = response.upload_method
//         file.uploadHeaders = response.upload_headers
//         file.assetID = response.asset_id
//         done()
//       error: (response) ->
//         done("Failed to initiate the upload process!")

// window.WCC.tessaInit = (sel) ->
//   sel = sel || 'form:has(.tessa-upload)'
//   $(sel).each (i, form) ->
//     $form = $(form)
//     $form.bind 'submit', (event) ->
//       safeToSubmit = true
//       $form.find('.tessa-upload').each (j, dropzoneElement) ->
//         $(dropzoneElement.dropzone.files).each (k, file) ->
//           if file.status? and (file.status != WCC.Dropzone.SUCCESS)
//             safeToSubmit = false
//       if not safeToSubmit and not confirm(WCC.Dropzone.uploadPendingWarning)
//         return false

//   $('.tessa-upload', sel).each (i, item) ->
//     $item = $(item)
//     args =
//       maxFiles: 1
//       addRemoveLinks: true

//     $.extend args, $item.data("dropzone-options")
//     args.maxFiles = null if $item.hasClass("multiple")
//     inputPrefix = $item.data("asset-field-prefix")

//     dropzone = new WCC.Dropzone item, args

//     $item.find('input[type="hidden"]').each (j, input) ->
//       $input = $(input)
//       mockFile = $input.data("meta")
//       mockFile.accepted = true
//       dropzone.options.addedfile.call(dropzone, mockFile)
//       dropzone.options.thumbnail.call(dropzone, mockFile, mockFile.url)
//       dropzone.emit("complete", mockFile)
//       dropzone.files.push mockFile

//     updateAction = (file) ->
//       return unless file.assetID?
//       inputID = "#tessa_asset_action_#{file.assetID}"
//       actionInput = $(inputID)
//       unless actionInput.length
//         actionInput = $('<input type="hidden">')
//           .attr
//             id: inputID
//             name: "#{inputPrefix}[#{file.assetID}][action]"
//           .appendTo item

//       actionInput.val file.action

//     dropzone.on 'success', (file) ->
//       file.action = "add"
//       updateAction(file)

//     dropzone.on 'removedfile', (file) ->
//       file.action = "remove"
//       updateAction(file)


// $ ->
//   window.WCC.tessaInit()

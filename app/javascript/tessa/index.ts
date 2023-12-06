import type Dropzone from 'dropzone'
import {FileChecksum} from '../activestorage/file_checksum'
import type { ActiveStorageDirectUploadParams, ActiveStorageDirectUploadResponse } from './types'

declare global {
  interface Window {
    WCC: any,
    jQuery: typeof jQuery,
    Dropzone: typeof Dropzone,
  }
}

window.WCC ||= {}
const $ = window.jQuery

window.Dropzone.autoDiscover = false

interface WCCDropzoneFile extends Dropzone.DropzoneFile {
  uploadURL: string,
  uploadMethod: string,
  uploadHeaders: Record<string, string> | undefined,
  signedID: string,
}

interface WCCDropzoneOptions extends Dropzone.DropzoneOptions {
  directUploadURL: string,
}

const BaseDropzone = window.Dropzone
class WCCDropzone extends BaseDropzone {
  readonly options!: WCCDropzoneOptions

  /**
   * Performs a direct upload to the signed upload URL created in "accept".
   * On complete, calls the Dropzone "success" callback.
   */
  uploadFile(file: WCCDropzoneFile): void {
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

const uploadPendingWarning = "File uploads have not yet completed. If you submit the form now they will not be saved. Are you sure you want to continue?"

const kb = 1000
const mb = 1000 * kb
const gb = 1000 * mb

/**
 * Called on page load to initialize the Dropzone
 */
function tessaInit() {
  $('.tessa-upload').each(function(i: number, item: HTMLElement) {
    const $item = $(item)

    const directUploadURL = $item.data('direct-upload-url') || '/rails/active_storage/direct_uploads'

    const options: WCCDropzoneOptions = {
      maxFiles: 1,
      // With a single PUT operation, you can upload a single object up to 5 GB in size.
      // https://docs.aws.amazon.com/AmazonS3/latest/userguide/upload-objects.html
      maxFilesize: 5 * gb,
      addRemoveLinks: true,
      url: 'UNUSED',
      dictDefaultMessage: 'Drop files or click to upload.',
      accept: createAcceptFn({ directUploadURL }),
      ...$item.data("dropzone-options")
    }

    if ($item.hasClass("multiple")) { options.maxFiles = undefined }

    const dropzone = new WCCDropzone(item, options)

    /**
     * On load, if an asset already exists, add it's thumbnail to the dropzone.
     */
    $item.find('input[type="hidden"]').each(function(i: number, input: HTMLElement) {
      const $input = $(input)
      const mockFile = $input.data("meta")
      if (!mockFile) { return }

      mockFile.accepted = true
      dropzone.options.addedfile?.call(dropzone, mockFile)
      dropzone.options.thumbnail?.call(dropzone, mockFile, mockFile.url)
      dropzone.emit("complete", mockFile)
      dropzone.files.push(mockFile)
    })

    const inputName = $item.data('input-name') || $item.find('input[type="hidden"]').attr('name');

    /**
     * On successful dropzone upload, create the hidden input with the signed ID.
     * On the server side, ActiveStorage can then use the signed ID to create an attachment to the blob.
     */
    dropzone.on('success', (file: WCCDropzoneFile) => {
      $(`input[name="${inputName}"]`).val(file.signedID)
    })

    /**
     * On dropzone file removal, delete the hidden input.  This removes the attachment from the record.
     */
    dropzone.on('removedfile', (file: WCCDropzoneFile) => {
      $item.find(`input[name="${inputName}"]`).val('')
    })
  })

  $('form:has(.tessa-upload)').each((i, form) => {
    const $form = $(form)
    $form.on('submit', (event: any) => {
      let safeToSubmit = true
      $form.find('.tessa-upload').each((j, dropzoneElement) => {
        (dropzoneElement.dropzone.files as WCCDropzoneFile[]).forEach((file) => {
          if (file.status && file.status != WCCDropzone.SUCCESS) {
            safeToSubmit = false
          }
        })
      })
      if (!safeToSubmit && !confirm(uploadPendingWarning)) {
        // prevent form submission
        return false
      }
    })
  })
}

interface AcceptOptions {
  directUploadURL: string
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
function createAcceptFn({ directUploadURL }: AcceptOptions) {
  return function(this: WCCDropzone, file: WCCDropzoneFile, done: (error?: string | Error) => void) {
    console.log('check file size', file.size, this.options.maxFilesize)
    if (this.options.maxFilesize && file.size > this.options.maxFilesize) {
      return done(
        `Uploads are limited to ${Math.floor(this.options.maxFilesize / gb)} Gigabytes.` +
        ` Your file is ${(file.size / gb).toFixed(2)} GB.` +
        ` Please contact helpdesk for assistance.`
      )
    }
    
    const postData: ActiveStorageDirectUploadParams = {
      blob: {
        filename: file.name,
        byte_size: file.size,
        content_type: file.type,
        checksum: ''
      }
    }

    FileChecksum.create(file, (error, checksum) => {
      if (error) {
        return done(error)
      }
      if (!checksum) {
        return done(`Failed to generate checksum for file '${file.name}'`)
      }

      postData.blob['checksum'] = checksum

      $.ajax(directUploadURL, {
        type: 'POST',
        data: postData,
        success: (response: ActiveStorageDirectUploadResponse) => {
          file.uploadURL = response.direct_upload.url
          file.uploadMethod = 'PUT' // ActiveStorage is always PUT
          file.uploadHeaders = response.direct_upload.headers
          file.signedID = response.signed_id
          done()
        },
        error: (response: any) => {
          console.error(response)
          done("Failed to initiate the upload process!")
        }
      })

    })
  }
}

$(tessaInit)

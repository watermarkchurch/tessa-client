import * as SparkMD5 from "spark-md5"

const fileSlice = File.prototype.slice || (File.prototype as any).mozSlice || (File.prototype as any).webkitSlice

type FileChecksumCallback = (error: string | null, checksum?: string) => void

export class FileChecksum {
  static create(file: File, callback: FileChecksumCallback) {
    const instance = new FileChecksum(file)
    instance.create(callback)
  }

  private file: File
  private chunkSize: number
  private chunkCount: number
  private chunkIndex: number
  private md5Buffer?: SparkMD5.ArrayBuffer
  private fileReader?: FileReader
  private callback?: FileChecksumCallback

  constructor(file: File) {
    this.file = file
    this.chunkSize = 2097152 // 2MB
    this.chunkCount = Math.ceil(this.file.size / this.chunkSize)
    this.chunkIndex = 0
  }

  create(callback: FileChecksumCallback) {
    this.callback = callback
    this.md5Buffer = new SparkMD5.ArrayBuffer
    this.fileReader = new FileReader
    this.fileReader.addEventListener("load", event => this.fileReaderDidLoad(event))
    this.fileReader.addEventListener("error", event => this.fileReaderDidError(event))
    this.readNextChunk()
  }

  private fileReaderDidLoad(event: ProgressEvent<FileReader>) {
    if (!this.md5Buffer || !this.fileReader) {
      throw new Error("FileChecksum: fileReaderDidLoad called before create")
    }
    if (!event.target?.result) { return }

    this.md5Buffer.append(event.target.result as ArrayBuffer)

    if (!this.readNextChunk()) {
      const binaryDigest = this.md5Buffer.end(true)
      const base64digest = btoa(binaryDigest)
      if (this.callback) {
        this.callback(null, base64digest)
      }
    }
  }

  private fileReaderDidError(event: ProgressEvent<FileReader>) {
    if (this.callback) {
      this.callback(`Error reading ${this.file.name}`)
    }
  }

  private readNextChunk() {
    if (!this.fileReader) {
      throw new Error("FileChecksum: readNextChunk called before create")
    }

    if (this.chunkIndex < this.chunkCount || (this.chunkIndex == 0 && this.chunkCount == 0)) {
      const start = this.chunkIndex * this.chunkSize
      const end = Math.min(start + this.chunkSize, this.file.size)
      const bytes = fileSlice.call(this.file, start, end)
      this.fileReader.readAsArrayBuffer(bytes)
      this.chunkIndex++
      return true
    } else {
      return false
    }
  }
}

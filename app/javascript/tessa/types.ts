
export interface ActiveStorageDirectUploadParams {
  blob: {
    filename: string,
    byte_size: number,
    checksum: string,
    content_type: string
    metadata?: Record<string, string>
  }
}

type Stringable = { toString(): string }

export interface ActiveStorageDirectUploadResponse {
  "id": Stringable,
  "key": string,
  "filename": string,
  "content_type": string,
  "metadata"?: {
    "identified"?: boolean
  },
  "byte_size": number,
  "checksum": string,
  "created_at": string,
  "service_name": string,
  "signed_id": string,
  "attachable_sgid": string,
  "direct_upload": {
    "url": string,
    "headers"?: {
      "Content-Type"?: string
    }
  }
}

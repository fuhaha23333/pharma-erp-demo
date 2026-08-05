import axios, { AxiosError, type AxiosRequestConfig } from 'axios'
import type { ApiEnvelope } from '@/types/api'
import {
  clearCredential,
  getAuthorizationHeader,
  hasCredential,
} from '@/security/credentialVault'

export class ApiError extends Error {
  readonly code: number
  readonly status: number

  constructor(message: string, code: number, status: number) {
    super(message)
    this.name = 'ApiError'
    this.code = code
    this.status = status
  }
}

let unauthorizedHandler: (() => void) | undefined

export function installUnauthorizedHandler(handler: () => void): void {
  unauthorizedHandler = handler
}

const client = axios.create({
  baseURL: import.meta.env.VITE_API_BASE_URL || '/api',
  timeout: 15_000,
  headers: {
    Accept: 'application/json',
    'Content-Type': 'application/json',
  },
})

client.interceptors.request.use((config) => {
  const authorization = getAuthorizationHeader()
  if (authorization) {
    config.headers.Authorization = authorization
  }
  return config
})

client.interceptors.response.use(
  (response) => response,
  (error: AxiosError<ApiEnvelope<unknown>>) => {
    const status = error.response?.status ?? 0
    const code = error.response?.data?.code ?? status
    const message =
      error.response?.data?.message ||
      (status === 0 ? '无法连接后端服务，请检查服务是否启动' : '请求失败，请稍后重试')

    if (status === 401 && hasCredential()) {
      clearCredential()
      unauthorizedHandler?.()
    }

    return Promise.reject(new ApiError(message, code || 500, status))
  },
)

export async function request<T>(config: AxiosRequestConfig): Promise<T> {
  const response = await client.request<ApiEnvelope<T>>(config)
  const envelope = response.data
  if (envelope.code !== 200) {
    throw new ApiError(envelope.message || '操作失败', envelope.code, response.status)
  }
  return envelope.data
}

export function getErrorMessage(error: unknown): string {
  if (error instanceof ApiError) {
    return error.message
  }
  if (error instanceof Error) {
    return error.message
  }
  return '操作失败，请稍后重试'
}

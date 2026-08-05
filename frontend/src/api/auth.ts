import { request } from '@/api/http'
import type { CurrentUser } from '@/types/system'

export function getCurrentUser(): Promise<CurrentUser> {
  return request<CurrentUser>({
    method: 'GET',
    url: '/system/auth/me',
  })
}

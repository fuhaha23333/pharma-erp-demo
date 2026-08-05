import { computed, reactive, readonly } from 'vue'
import { getCurrentUser } from '@/api/auth'
import type { PermissionCode } from '@/constants/permissions'
import { clearCredential, setCredential } from '@/security/credentialVault'
import type { CurrentUser } from '@/types/system'

interface AuthState {
  user: CurrentUser | null
  authenticating: boolean
}

const state = reactive<AuthState>({
  user: null,
  authenticating: false,
})

const permissionSet = computed(() => new Set(state.user?.permissionCodes ?? []))

export const authState = readonly(state)
export const isAuthenticated = computed(() => state.user !== null)

export async function login(username: string, password: string): Promise<CurrentUser> {
  state.authenticating = true
  setCredential(username.trim(), password)
  try {
    const user = await getCurrentUser()
    state.user = user
    return user
  } catch (error) {
    clearCredential()
    state.user = null
    throw error
  } finally {
    state.authenticating = false
  }
}

export function logout(): void {
  clearCredential()
  state.user = null
}

export function expireSession(): void {
  clearCredential()
  state.user = null
}

export function hasPermission(permission?: PermissionCode | string): boolean {
  if (!permission) {
    return true
  }
  return permissionSet.value.has(permission)
}

export function hasAnyPermission(permissions: Array<PermissionCode | string>): boolean {
  return permissions.some((permission) => permissionSet.value.has(permission))
}

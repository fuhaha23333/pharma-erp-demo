import { getCurrentUser } from '@/api/auth'
import { getAuthorizationHeader } from '@/security/credentialVault'
import {
  authState,
  hasAnyPermission,
  hasPermission,
  login,
  logout,
} from '@/stores/auth'

vi.mock('@/api/auth', () => ({
  getCurrentUser: vi.fn(),
}))

const mockedGetCurrentUser = vi.mocked(getCurrentUser)

describe('auth store', () => {
  beforeEach(() => {
    logout()
    mockedGetCurrentUser.mockReset()
  })

  it('认证成功后只保存当前用户和后端权限', async () => {
    mockedGetCurrentUser.mockResolvedValue({
      id: 1,
      username: 'admin',
      displayName: '系统管理员',
      departmentId: 1,
      departmentName: '示例企业',
      roleCodes: ['SUPER_ADMIN'],
      permissionCodes: ['SYS_USER_READ', 'TRACE_READ'],
    })

    await login('admin', 'Secret123!')

    expect(authState.user?.username).toBe('admin')
    expect(hasPermission('SYS_USER_READ')).toBe(true)
    expect(hasPermission('SUPPLIER_REVIEW')).toBe(false)
    expect(hasAnyPermission(['SUPPLIER_READ', 'TRACE_READ'])).toBe(true)
    expect(getAuthorizationHeader()).toContain('Basic ')
  })

  it('认证失败时同时清除用户和内存凭据', async () => {
    mockedGetCurrentUser.mockRejectedValue(new Error('认证失败'))

    await expect(login('admin', 'wrong')).rejects.toThrow('认证失败')

    expect(authState.user).toBeNull()
    expect(getAuthorizationHeader()).toBeUndefined()
  })
})

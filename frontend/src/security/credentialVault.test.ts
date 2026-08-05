import {
  clearCredential,
  getAuthorizationHeader,
  hasCredential,
  setCredential,
} from '@/security/credentialVault'

describe('credentialVault', () => {
  afterEach(clearCredential)

  it('只在内存中生成标准 Basic Authorization', () => {
    setCredential('admin', 'Secret123!')

    expect(hasCredential()).toBe(true)
    expect(getAuthorizationHeader()).toBe('Basic YWRtaW46U2VjcmV0MTIzIQ==')
  })

  it('正确编码 UTF-8 密码且可立即清除', () => {
    setCredential('quality.head', '密码-安全')
    const encoded = getAuthorizationHeader()?.replace('Basic ', '') || ''
    const bytes = Uint8Array.from(atob(encoded), (char) => char.charCodeAt(0))

    expect(new TextDecoder().decode(bytes)).toBe('quality.head:密码-安全')

    clearCredential()
    expect(hasCredential()).toBe(false)
    expect(getAuthorizationHeader()).toBeUndefined()
  })
})

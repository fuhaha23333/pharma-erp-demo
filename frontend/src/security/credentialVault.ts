interface Credential {
  username: string
  password: string
}

let currentCredential: Credential | null = null

function encodeUtf8Base64(value: string): string {
  const bytes = new TextEncoder().encode(value)
  let binary = ''
  for (const byte of bytes) {
    binary += String.fromCharCode(byte)
  }
  return btoa(binary)
}

export function setCredential(username: string, password: string): void {
  currentCredential = { username, password }
}

export function clearCredential(): void {
  currentCredential = null
}

export function hasCredential(): boolean {
  return currentCredential !== null
}

export function getAuthorizationHeader(): string | undefined {
  if (!currentCredential) {
    return undefined
  }
  return `Basic ${encodeUtf8Base64(`${currentCredential.username}:${currentCredential.password}`)}`
}

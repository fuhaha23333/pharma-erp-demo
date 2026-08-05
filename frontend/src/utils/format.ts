export function formatFileSize(bytes?: number): string {
  if (bytes === undefined || bytes === null) {
    return '—'
  }
  if (bytes < 1024) {
    return `${bytes} B`
  }
  if (bytes < 1024 * 1024) {
    return `${(bytes / 1024).toFixed(1)} KB`
  }
  return `${(bytes / 1024 / 1024).toFixed(1)} MB`
}

export function optionalText(value?: string): string | undefined {
  const trimmed = value?.trim()
  return trimmed ? trimmed : undefined
}

export function compactParams<T extends object>(params: T): Partial<T> {
  return Object.fromEntries(
    Object.entries(params as Record<string, unknown>).filter(
      ([, value]) => value !== '' && value !== undefined && value !== null,
    ),
  ) as Partial<T>
}

export function safeJson(value?: string): { formatted: string; valid: boolean } {
  if (!value) {
    return { formatted: '无事件快照', valid: true }
  }
  try {
    return { formatted: JSON.stringify(JSON.parse(value), null, 2), valid: true }
  } catch {
    return { formatted: value, valid: false }
  }
}

const UTC_OFFSET_PATTERN = /(Z|[+-]\d{2}:?\d{2})$/i

export function parseServerDateTime(value?: string | null): Date | null {
  if (!value) {
    return null
  }
  const normalized = UTC_OFFSET_PATTERN.test(value) ? value : `${value}Z`
  const date = new Date(normalized)
  return Number.isNaN(date.getTime()) ? null : date
}

export function formatDateTime(value?: string | null): string {
  const date = parseServerDateTime(value)
  if (!date) {
    return '—'
  }
  return new Intl.DateTimeFormat('zh-CN', {
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit',
    hour12: false,
  }).format(date)
}

export function formatDate(value?: string | null): string {
  return value || '长期有效'
}

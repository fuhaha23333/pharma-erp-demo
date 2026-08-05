import { parseServerDateTime } from '@/utils/datetime'

describe('UTC 时间解析', () => {
  it('把后端无时区 LocalDateTime 按 UTC 处理', () => {
    expect(parseServerDateTime('2026-08-04T08:30:00')?.toISOString()).toBe(
      '2026-08-04T08:30:00.000Z',
    )
  })

  it('保留显式时区并处理空值', () => {
    expect(parseServerDateTime('2026-08-04T16:30:00+08:00')?.toISOString()).toBe(
      '2026-08-04T08:30:00.000Z',
    )
    expect(parseServerDateTime()).toBeNull()
  })
})

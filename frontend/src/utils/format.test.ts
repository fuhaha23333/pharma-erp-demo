import { compactParams, safeJson } from '@/utils/format'

describe('通用格式工具', () => {
  it('查询参数移除空值但保留数字零和 false', () => {
    expect(
      compactParams({
        keyword: '',
        pageNo: 1,
        disabled: false,
        parentId: undefined,
      }),
    ).toEqual({ pageNo: 1, disabled: false })
  })

  it('事件证据只格式化真实 JSON，非法文本保持原样', () => {
    expect(safeJson('{"result":"ok"}')).toEqual({
      formatted: '{\n  "result": "ok"\n}',
      valid: true,
    })
    expect(safeJson('not-json')).toEqual({ formatted: 'not-json', valid: false })
  })
})

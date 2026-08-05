import { mount } from '@vue/test-utils'
import ReviewDecisionField from '@/components/ReviewDecisionField.vue'

describe('ReviewDecisionField', () => {
  it('渲染两个可选择的审核决定，并显示默认通过状态', () => {
    const wrapper = mount(ReviewDecisionField, {
      props: {
        modelValue: 'APPROVED',
      },
    })

    const options = wrapper.findAll('.el-radio-button')

    expect(options).toHaveLength(2)
    expect(options[0].text()).toContain('审核通过')
    expect(options[1].text()).toContain('审核驳回')
    expect(options[0].classes()).toContain('is-active')
    expect(wrapper.findAll('input[type="radio"]')).toHaveLength(2)
  })

  it('点击审核驳回时向父页面提交 REJECTED', async () => {
    const wrapper = mount(ReviewDecisionField, {
      props: {
        modelValue: 'APPROVED',
      },
    })

    await wrapper.findAll<HTMLInputElement>('input[type="radio"]')[1].setValue(true)

    expect(wrapper.emitted('update:modelValue')).toEqual([['REJECTED']])
  })
})

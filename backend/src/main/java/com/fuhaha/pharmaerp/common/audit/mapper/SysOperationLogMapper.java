package com.fuhaha.pharmaerp.common.audit.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.fuhaha.pharmaerp.common.audit.entity.SysOperationLog;
import org.apache.ibatis.annotations.Mapper;

@Mapper
public interface SysOperationLogMapper extends BaseMapper<SysOperationLog> {
}

package com.fuhaha.pharmaerp.modules.master.drug.service;

import com.fuhaha.pharmaerp.common.page.PageResult;
import com.fuhaha.pharmaerp.modules.master.drug.dto.DrugCreateDTO;
import com.fuhaha.pharmaerp.modules.master.drug.dto.DrugPageQueryDTO;
import com.fuhaha.pharmaerp.modules.master.drug.dto.DrugUpdateDTO;
import com.fuhaha.pharmaerp.modules.master.drug.vo.DrugVO;

public interface DrugService {

    DrugVO create(DrugCreateDTO dto);

    DrugVO update(Long id, DrugUpdateDTO dto);

    DrugVO getDetail(Long id);

    PageResult<DrugVO> page(DrugPageQueryDTO query);

    void enable(Long id);

    void disable(Long id);
}

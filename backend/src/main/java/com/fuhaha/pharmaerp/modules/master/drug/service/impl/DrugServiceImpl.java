package com.fuhaha.pharmaerp.modules.master.drug.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.fuhaha.pharmaerp.common.exception.BizException;
import com.fuhaha.pharmaerp.common.page.PageResult;
import com.fuhaha.pharmaerp.modules.master.drug.dto.DrugCreateDTO;
import com.fuhaha.pharmaerp.modules.master.drug.dto.DrugPageQueryDTO;
import com.fuhaha.pharmaerp.modules.master.drug.dto.DrugUpdateDTO;
import com.fuhaha.pharmaerp.modules.master.drug.entity.Drug;
import com.fuhaha.pharmaerp.modules.master.drug.enums.DrugStatusEnum;
import com.fuhaha.pharmaerp.modules.master.drug.mapper.DrugMapper;
import com.fuhaha.pharmaerp.modules.master.drug.service.DrugService;
import com.fuhaha.pharmaerp.modules.master.drug.vo.DrugVO;
import java.util.List;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

@Service
public class DrugServiceImpl implements DrugService {

    private final DrugMapper drugMapper;

    public DrugServiceImpl(DrugMapper drugMapper) {
        this.drugMapper = drugMapper;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public DrugVO create(DrugCreateDTO dto) {
        validateCreate(dto);
        checkDrugCodeNotExists(dto.getDrugCode());

        Drug drug = new Drug();
        drug.setDrugCode(dto.getDrugCode().trim());
        drug.setDrugName(dto.getDrugName().trim());
        drug.setGenericName(dto.getGenericName().trim());
        drug.setApprovalNo(dto.getApprovalNo().trim());
        drug.setDosageForm(dto.getDosageForm().trim());
        drug.setSpecification(dto.getSpecification().trim());
        drug.setManufacturer(dto.getManufacturer().trim());
        drug.setBasicUnit(dto.getBasicUnit().trim());
        drug.setStorageCondition(dto.getStorageCondition().trim());
        drug.setStatus(DrugStatusEnum.DISABLED.getCode());
        drug.setRemark(trimToNull(dto.getRemark()));

        drugMapper.insert(drug);
        return toVO(getByIdOrThrow(drug.getId()));
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public DrugVO update(Long id, DrugUpdateDTO dto) {
        Drug drug = getByIdOrThrow(id);
        validateUpdate(dto);

        drug.setDrugName(dto.getDrugName().trim());
        drug.setGenericName(dto.getGenericName().trim());
        drug.setApprovalNo(dto.getApprovalNo().trim());
        drug.setDosageForm(dto.getDosageForm().trim());
        drug.setSpecification(dto.getSpecification().trim());
        drug.setManufacturer(dto.getManufacturer().trim());
        drug.setBasicUnit(dto.getBasicUnit().trim());
        drug.setStorageCondition(dto.getStorageCondition().trim());
        drug.setRemark(trimToNull(dto.getRemark()));

        drugMapper.updateById(drug);
        return toVO(getByIdOrThrow(id));
    }

    @Override
    public DrugVO getDetail(Long id) {
        return toVO(getByIdOrThrow(id));
    }

    @Override
    public PageResult<DrugVO> page(DrugPageQueryDTO query) {
        validatePageQuery(query);

        Page<Drug> page = new Page<>(query.getPageNo(), query.getPageSize());
        LambdaQueryWrapper<Drug> wrapper = new LambdaQueryWrapper<Drug>()
                .like(hasText(query.getDrugCode()), Drug::getDrugCode, trim(query.getDrugCode()))
                .like(hasText(query.getDrugName()), Drug::getDrugName, trim(query.getDrugName()))
                .like(hasText(query.getGenericName()), Drug::getGenericName, trim(query.getGenericName()))
                .like(hasText(query.getApprovalNo()), Drug::getApprovalNo, trim(query.getApprovalNo()))
                .like(hasText(query.getManufacturer()), Drug::getManufacturer, trim(query.getManufacturer()))
                .eq(hasText(query.getStatus()), Drug::getStatus, trim(query.getStatus()))
                .orderByDesc(Drug::getCreatedAt)
                .orderByDesc(Drug::getId);

        Page<Drug> result = drugMapper.selectPage(page, wrapper);
        List<DrugVO> records = result.getRecords().stream().map(this::toVO).toList();
        return PageResult.of(records, result.getTotal(), query.getPageNo(), query.getPageSize());
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void enable(Long id) {
        Drug drug = getByIdOrThrow(id);
        if (DrugStatusEnum.ENABLED.getCode().equals(drug.getStatus())) {
            return;
        }

        validateCoreFields(drug);
        drug.setStatus(DrugStatusEnum.ENABLED.getCode());
        drugMapper.updateById(drug);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void disable(Long id) {
        Drug drug = getByIdOrThrow(id);
        if (DrugStatusEnum.DISABLED.getCode().equals(drug.getStatus())) {
            return;
        }

        drug.setStatus(DrugStatusEnum.DISABLED.getCode());
        drugMapper.updateById(drug);
    }

    private void validateCreate(DrugCreateDTO dto) {
        if (dto == null) {
            throw new BizException("药品信息不能为空");
        }
        requireText(dto.getDrugCode(), "药品编码不能为空");
        requireCoreFields(
                dto.getDrugName(),
                dto.getGenericName(),
                dto.getApprovalNo(),
                dto.getDosageForm(),
                dto.getSpecification(),
                dto.getManufacturer(),
                dto.getBasicUnit(),
                dto.getStorageCondition());
    }

    private void validateUpdate(DrugUpdateDTO dto) {
        if (dto == null) {
            throw new BizException("药品信息不能为空");
        }
        requireCoreFields(
                dto.getDrugName(),
                dto.getGenericName(),
                dto.getApprovalNo(),
                dto.getDosageForm(),
                dto.getSpecification(),
                dto.getManufacturer(),
                dto.getBasicUnit(),
                dto.getStorageCondition());
    }

    private void validatePageQuery(DrugPageQueryDTO query) {
        if (query == null) {
            throw new BizException("分页查询参数不能为空");
        }
        if (query.getPageNo() == null || query.getPageNo() < 1) {
            throw new BizException("页码不能小于1");
        }
        if (query.getPageSize() == null || query.getPageSize() < 1 || query.getPageSize() > 100) {
            throw new BizException("每页条数必须在1到100之间");
        }
        if (hasText(query.getStatus()) && !DrugStatusEnum.isValid(trim(query.getStatus()))) {
            throw new BizException("状态值非法");
        }
    }

    private void requireCoreFields(
            String drugName,
            String genericName,
            String approvalNo,
            String dosageForm,
            String specification,
            String manufacturer,
            String basicUnit,
            String storageCondition) {
        requireText(drugName, "药品名称不能为空");
        requireText(genericName, "药品通用名称不能为空");
        requireText(approvalNo, "批准文号不能为空");
        requireText(dosageForm, "剂型不能为空");
        requireText(specification, "规格不能为空");
        requireText(manufacturer, "生产厂家不能为空");
        requireText(basicUnit, "基本单位不能为空");
        requireText(storageCondition, "储存条件不能为空");
    }

    private void validateCoreFields(Drug drug) {
        requireText(drug.getDrugCode(), "药品编码不能为空");
        requireCoreFields(
                drug.getDrugName(),
                drug.getGenericName(),
                drug.getApprovalNo(),
                drug.getDosageForm(),
                drug.getSpecification(),
                drug.getManufacturer(),
                drug.getBasicUnit(),
                drug.getStorageCondition());
    }

    private void checkDrugCodeNotExists(String drugCode) {
        Long count = drugMapper.selectCount(new LambdaQueryWrapper<Drug>()
                .eq(Drug::getDrugCode, drugCode.trim()));
        if (count != null && count > 0) {
            throw new BizException("药品编码已存在");
        }
    }

    private Drug getByIdOrThrow(Long id) {
        if (id == null) {
            throw new BizException("药品ID不能为空");
        }
        Drug drug = drugMapper.selectById(id);
        if (drug == null) {
            throw new BizException("药品不存在");
        }
        return drug;
    }

    private DrugVO toVO(Drug drug) {
        DrugVO vo = new DrugVO();
        vo.setId(drug.getId());
        vo.setDrugCode(drug.getDrugCode());
        vo.setDrugName(drug.getDrugName());
        vo.setGenericName(drug.getGenericName());
        vo.setApprovalNo(drug.getApprovalNo());
        vo.setDosageForm(drug.getDosageForm());
        vo.setSpecification(drug.getSpecification());
        vo.setManufacturer(drug.getManufacturer());
        vo.setBasicUnit(drug.getBasicUnit());
        vo.setStorageCondition(drug.getStorageCondition());
        vo.setStatus(drug.getStatus());
        vo.setStatusName(DrugStatusEnum.getNameByCode(drug.getStatus()));
        vo.setRemark(drug.getRemark());
        vo.setCreatedAt(drug.getCreatedAt());
        vo.setUpdatedAt(drug.getUpdatedAt());
        return vo;
    }

    private void requireText(String value, String message) {
        if (!hasText(value)) {
            throw new BizException(message);
        }
    }

    private boolean hasText(String value) {
        return StringUtils.hasText(value);
    }

    private String trim(String value) {
        return value == null ? null : value.trim();
    }

    private String trimToNull(String value) {
        String trimmed = trim(value);
        return hasText(trimmed) ? trimmed : null;
    }
}

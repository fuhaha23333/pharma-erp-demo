package com.fuhaha.pharmaerp.modules.master.drug.controller;

import com.fuhaha.pharmaerp.common.page.PageResult;
import com.fuhaha.pharmaerp.common.result.Result;
import com.fuhaha.pharmaerp.modules.master.drug.dto.DrugCreateDTO;
import com.fuhaha.pharmaerp.modules.master.drug.dto.DrugPageQueryDTO;
import com.fuhaha.pharmaerp.modules.master.drug.dto.DrugUpdateDTO;
import com.fuhaha.pharmaerp.modules.master.drug.service.DrugService;
import com.fuhaha.pharmaerp.modules.master.drug.vo.DrugVO;
import jakarta.validation.Valid;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@Validated
@RestController
@RequestMapping("/master/drugs")
public class DrugController {

    private final DrugService drugService;

    public DrugController(DrugService drugService) {
        this.drugService = drugService;
    }

    @PostMapping
    public Result<DrugVO> create(@Valid @RequestBody DrugCreateDTO dto) {
        return Result.success(drugService.create(dto));
    }

    @PutMapping("/{id}")
    public Result<DrugVO> update(@PathVariable Long id, @Valid @RequestBody DrugUpdateDTO dto) {
        return Result.success(drugService.update(id, dto));
    }

    @GetMapping("/{id}")
    public Result<DrugVO> getDetail(@PathVariable Long id) {
        return Result.success(drugService.getDetail(id));
    }

    @GetMapping("/page")
    public Result<PageResult<DrugVO>> page(@Valid DrugPageQueryDTO query) {
        return Result.success(drugService.page(query));
    }

    @PutMapping("/{id}/enable")
    public Result<Void> enable(@PathVariable Long id) {
        drugService.enable(id);
        return Result.success();
    }

    @PutMapping("/{id}/disable")
    public Result<Void> disable(@PathVariable Long id) {
        drugService.disable(id);
        return Result.success();
    }
}

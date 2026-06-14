package com.fuhaha.pharmaerp.modules.system.controller;

import com.fuhaha.pharmaerp.common.result.Result;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class HealthController {

    @GetMapping("/health")
    public Result<String> health() {
        return Result.success("pharma-erp is running");
    }
}

package com.fuhaha.pharmaerp.modules.master.drug.enums;

import java.util.Arrays;
import lombok.Getter;

@Getter
public enum DrugStatusEnum {

    ENABLED("ENABLED", "启用"),
    DISABLED("DISABLED", "停用");

    private final String code;
    private final String name;

    DrugStatusEnum(String code, String name) {
        this.code = code;
        this.name = name;
    }

    public static boolean isValid(String code) {
        return Arrays.stream(values()).anyMatch(status -> status.code.equals(code));
    }

    public static String getNameByCode(String code) {
        return Arrays.stream(values())
                .filter(status -> status.code.equals(code))
                .map(DrugStatusEnum::getName)
                .findFirst()
                .orElse("");
    }
}

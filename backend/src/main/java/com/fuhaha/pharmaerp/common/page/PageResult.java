package com.fuhaha.pharmaerp.common.page;

import java.util.Collections;
import java.util.List;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class PageResult<T> {

    private List<T> records;
    private long total;
    private long pageNo;
    private long pageSize;

    public static <T> PageResult<T> empty(long pageNo, long pageSize) {
        return new PageResult<>(Collections.emptyList(), 0, pageNo, pageSize);
    }

    public static <T> PageResult<T> of(List<T> records, long total, long pageNo, long pageSize) {
        return new PageResult<>(records, total, pageNo, pageSize);
    }
}

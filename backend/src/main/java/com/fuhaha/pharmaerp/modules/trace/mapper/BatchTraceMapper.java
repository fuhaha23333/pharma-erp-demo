package com.fuhaha.pharmaerp.modules.trace.mapper;

import com.fuhaha.pharmaerp.modules.trace.vo.BatchInventoryVO;
import com.fuhaha.pharmaerp.modules.trace.vo.BatchTraceEventVO;
import com.fuhaha.pharmaerp.modules.trace.vo.DrugBatchTraceVO;
import java.util.List;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;

@Mapper
public interface BatchTraceMapper {

    @Select("""
            <script>
            SELECT
                db.id AS batch_id,
                db.batch_code,
                db.batch_no,
                d.id AS drug_id,
                d.drug_code,
                d.drug_name,
                d.generic_name,
                d.approval_no,
                d.dosage_form,
                d.specification,
                d.basic_unit,
                d.storage_condition,
                m.id AS manufacturer_id,
                m.manufacturer_code,
                m.manufacturer_name,
                db.production_date,
                db.expiry_date,
                db.quality_status,
                db.stock_status
            FROM drug_batch db
            INNER JOIN drug d ON d.id = db.drug_id
            INNER JOIN manufacturer m ON m.id = db.manufacturer_id
            WHERE db.batch_no = #{batchNo}
            <if test="drugCode != null and drugCode != ''">
                AND d.drug_code = #{drugCode}
            </if>
            ORDER BY d.drug_code, db.expiry_date, db.id
            </script>
            """)
    List<DrugBatchTraceVO> selectBatches(
            @Param("batchNo") String batchNo,
            @Param("drugCode") String drugCode);

    @Select("""
            SELECT
                ib.id AS inventory_balance_id,
                w.id AS warehouse_id,
                w.warehouse_code,
                w.warehouse_name,
                wl.id AS warehouse_location_id,
                wl.location_code,
                wl.location_name,
                wl.location_type,
                ib.total_quantity,
                ib.available_quantity,
                ib.reserved_quantity,
                ib.quarantined_quantity,
                ib.status,
                il.ledger_no AS last_ledger_no
            FROM inventory_balance ib
            INNER JOIN warehouse w ON w.id = ib.warehouse_id
            INNER JOIN warehouse_location wl ON wl.id = ib.warehouse_location_id
            LEFT JOIN inventory_ledger il ON il.id = ib.last_ledger_id
            WHERE ib.drug_batch_id = #{batchId}
            ORDER BY w.warehouse_code, wl.location_code
            """)
    List<BatchInventoryVO> selectInventories(@Param("batchId") Long batchId);

    @Select("""
            SELECT
                e.id AS event_id,
                e.event_no,
                e.event_type,
                s.supplier_code,
                s.supplier_name,
                c.customer_code,
                c.customer_name,
                w.warehouse_code,
                w.warehouse_name,
                wl.location_code,
                wl.location_name,
                il.ledger_no AS inventory_ledger_no,
                e.business_type,
                e.business_id,
                e.business_no,
                e.quantity,
                CAST(e.event_data AS CHAR) AS event_data,
                e.operator_id,
                u.username AS operator_username,
                u.display_name AS operator_real_name,
                e.occurred_at
            FROM batch_trace_event e
            LEFT JOIN supplier s ON s.id = e.supplier_id
            LEFT JOIN customer c ON c.id = e.customer_id
            LEFT JOIN warehouse w ON w.id = e.warehouse_id
            LEFT JOIN warehouse_location wl ON wl.id = e.warehouse_location_id
            LEFT JOIN inventory_ledger il ON il.id = e.inventory_ledger_id
            LEFT JOIN sys_user u ON u.id = e.operator_id
            WHERE e.drug_batch_id = #{batchId}
            ORDER BY e.occurred_at, e.id
            """)
    List<BatchTraceEventVO> selectEvents(@Param("batchId") Long batchId);
}

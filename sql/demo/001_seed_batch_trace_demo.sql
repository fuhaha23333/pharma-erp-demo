-- 药品批号追溯固定演示数据
-- 适用数据库：pharma_erp（MySQL 8）
-- 演示查询：
--   生产批号：DEMO20260701A
--   药品编码：DRUG-DEMO-001（可选）
--
-- 说明：
-- 1. 本脚本只使用 DEMO-TRACE / DEMO-* 前缀的新数据，不覆盖现有业务记录。
-- 2. 脚本可重复执行；固定业务编号存在时不会再次插入。
-- 3. 库存余额的每次变化都有对应 inventory_ledger，并在同一事务中完成。
-- 4. 这是验证型 Demo 的固定业务快照，不代表真实药品经营数据。

USE pharma_erp;

SET NAMES utf8mb4;
SET SESSION time_zone = '+00:00';

START TRANSACTION;

SET @demo_admin_id = (
    SELECT id FROM sys_user WHERE username = 'admin' AND status = 'ACTIVE' LIMIT 1
);
SET @demo_purchaser_id = (
    SELECT id FROM sys_user WHERE username = 'purchaser_demo' AND status = 'ACTIVE' LIMIT 1
);
SET @demo_quality_id = (
    SELECT id FROM sys_user WHERE username = 'quality_demo' AND status = 'ACTIVE' LIMIT 1
);
SET @demo_department_id = (
    SELECT id FROM sys_department WHERE department_code = 'ROOT' AND status = 'ACTIVE' LIMIT 1
);

-- ============================================================================
-- 1. 上下游企业、药品和仓储主数据
-- ============================================================================

INSERT INTO manufacturer (
    manufacturer_code,
    manufacturer_name,
    unified_social_credit_code,
    production_license_no,
    contact_name,
    contact_phone,
    address,
    status,
    created_by,
    created_at,
    updated_by,
    updated_at
)
SELECT
    'MFR-DEMO-001',
    '岭南示范制药有限公司（演示数据）',
    '91440101DEMO000011',
    '粤-DEMO-2026-0001',
    '陈生产',
    '020-88880001',
    '广东省广州市演示产业园 1 号',
    'ACTIVE',
    @demo_admin_id,
    '2026-06-10 01:00:00.000',
    @demo_admin_id,
    '2026-06-10 01:00:00.000'
WHERE NOT EXISTS (
    SELECT 1 FROM manufacturer WHERE manufacturer_code = 'MFR-DEMO-001'
);

SET @demo_manufacturer_id = (
    SELECT id FROM manufacturer WHERE manufacturer_code = 'MFR-DEMO-001' LIMIT 1
);

INSERT INTO drug (
    drug_code,
    drug_name,
    generic_name,
    approval_no,
    dosage_form,
    specification,
    manufacturer_id,
    basic_unit,
    storage_condition,
    status,
    remark,
    created_by,
    created_at,
    updated_by,
    updated_at
)
SELECT
    'DRUG-DEMO-001',
    '岭南阿莫西林胶囊（演示）',
    '阿莫西林胶囊',
    '国药准字HDEMO2026001',
    '胶囊剂',
    '0.25g×24粒/盒',
    @demo_manufacturer_id,
    '盒',
    '密封，在阴凉干燥处保存',
    'ACTIVE',
    '仅用于批号追溯功能演示，不是真实药品档案',
    @demo_quality_id,
    '2026-06-12 01:00:00.000',
    @demo_quality_id,
    '2026-06-12 01:00:00.000'
WHERE NOT EXISTS (
    SELECT 1 FROM drug WHERE drug_code = 'DRUG-DEMO-001'
);

SET @demo_drug_id = (
    SELECT id FROM drug WHERE drug_code = 'DRUG-DEMO-001' LIMIT 1
);

INSERT INTO supplier (
    supplier_code,
    supplier_name,
    supplier_type,
    unified_social_credit_code,
    contact_name,
    contact_phone,
    contact_email,
    address,
    qualification_status,
    approved_at,
    valid_until,
    created_by,
    created_at,
    updated_by,
    updated_at
)
SELECT
    'SUP-DEMO-TRACE-001',
    '广东追溯演示医药有限公司（演示数据）',
    'WHOLESALE',
    '91440101DEMO000021',
    '林采购',
    '020-88880002',
    'supplier-demo@example.test',
    '广东省广州市演示医药物流园 2 号',
    'APPROVED',
    '2026-06-20 03:00:00.000',
    '2028-12-31',
    @demo_purchaser_id,
    '2026-06-15 01:00:00.000',
    @demo_quality_id,
    '2026-06-20 03:00:00.000'
WHERE NOT EXISTS (
    SELECT 1 FROM supplier WHERE supplier_code = 'SUP-DEMO-TRACE-001'
);

SET @demo_supplier_id = (
    SELECT id FROM supplier WHERE supplier_code = 'SUP-DEMO-TRACE-001' LIMIT 1
);

INSERT INTO supplier_qualification (
    supplier_id,
    qualification_type,
    certificate_no,
    issuing_authority,
    issued_on,
    valid_from,
    valid_until,
    status,
    remark,
    created_by,
    created_at,
    updated_by,
    updated_at
)
SELECT
    @demo_supplier_id,
    'BUSINESS_LICENSE',
    'DEMO-TRACE-SUP-BL-001',
    '广州市市场监督管理局（演示）',
    '2025-01-01',
    '2025-01-01',
    '2029-12-31',
    'VALID',
    '固定演示资质',
    @demo_purchaser_id,
    '2026-06-15 01:10:00.000',
    @demo_quality_id,
    '2026-06-20 03:00:00.000'
WHERE NOT EXISTS (
    SELECT 1
    FROM supplier_qualification
    WHERE supplier_id = @demo_supplier_id
      AND qualification_type = 'BUSINESS_LICENSE'
      AND certificate_no = 'DEMO-TRACE-SUP-BL-001'
);

INSERT INTO supplier_qualification (
    supplier_id,
    qualification_type,
    certificate_no,
    issuing_authority,
    issued_on,
    valid_from,
    valid_until,
    status,
    remark,
    created_by,
    created_at,
    updated_by,
    updated_at
)
SELECT
    @demo_supplier_id,
    'DRUG_OPERATION_LICENSE',
    'DEMO-TRACE-SUP-DOL-001',
    '广东省药品监督管理局（演示）',
    '2025-01-01',
    '2025-01-01',
    '2028-12-31',
    'VALID',
    '固定演示资质',
    @demo_purchaser_id,
    '2026-06-15 01:20:00.000',
    @demo_quality_id,
    '2026-06-20 03:00:00.000'
WHERE NOT EXISTS (
    SELECT 1
    FROM supplier_qualification
    WHERE supplier_id = @demo_supplier_id
      AND qualification_type = 'DRUG_OPERATION_LICENSE'
      AND certificate_no = 'DEMO-TRACE-SUP-DOL-001'
);

INSERT INTO supplier_qualification (
    supplier_id,
    qualification_type,
    certificate_no,
    issuing_authority,
    issued_on,
    valid_from,
    valid_until,
    status,
    remark,
    created_by,
    created_at,
    updated_by,
    updated_at
)
SELECT
    @demo_supplier_id,
    'AUTHORIZATION',
    'DEMO-TRACE-SUP-AUTH-001',
    '岭南示范制药有限公司（演示）',
    '2026-01-01',
    '2026-01-01',
    '2028-12-31',
    'VALID',
    '固定演示授权',
    @demo_purchaser_id,
    '2026-06-15 01:30:00.000',
    @demo_quality_id,
    '2026-06-20 03:00:00.000'
WHERE NOT EXISTS (
    SELECT 1
    FROM supplier_qualification
    WHERE supplier_id = @demo_supplier_id
      AND qualification_type = 'AUTHORIZATION'
      AND certificate_no = 'DEMO-TRACE-SUP-AUTH-001'
);

INSERT INTO supplier_review (
    review_no,
    supplier_id,
    review_round,
    status,
    submitted_by,
    submitted_at,
    reviewer_id,
    reviewed_at,
    review_opinion,
    qualification_snapshot,
    approved_valid_until,
    created_at
)
SELECT
    'DEMO-TRACE-SUP-REV-001',
    @demo_supplier_id,
    1,
    'APPROVED',
    @demo_purchaser_id,
    '2026-06-20 01:00:00.000',
    @demo_quality_id,
    '2026-06-20 03:00:00.000',
    '营业执照、药品经营许可证及授权文件核验通过（演示）',
    JSON_OBJECT(
        'demo', TRUE,
        'qualificationCount', 3,
        'conclusion', 'APPROVED'
    ),
    '2028-12-31',
    '2026-06-20 01:00:00.000'
WHERE NOT EXISTS (
    SELECT 1 FROM supplier_review WHERE review_no = 'DEMO-TRACE-SUP-REV-001'
);

SET @demo_supplier_review_id = (
    SELECT id FROM supplier_review WHERE review_no = 'DEMO-TRACE-SUP-REV-001' LIMIT 1
);

INSERT INTO customer (
    customer_code,
    customer_name,
    customer_type,
    unified_social_credit_code,
    contact_name,
    contact_phone,
    contact_email,
    address,
    qualification_status,
    approved_at,
    valid_until,
    created_by,
    created_at,
    updated_by,
    updated_at
)
SELECT
    'CUS-DEMO-TRACE-001',
    '广州市演示人民医院（演示数据）',
    'MEDICAL',
    '91440101DEMO000031',
    '周药师',
    '020-88880003',
    'customer-demo@example.test',
    '广东省广州市演示大道 3 号',
    'APPROVED',
    '2026-06-22 03:00:00.000',
    '2028-12-31',
    @demo_admin_id,
    '2026-06-18 01:00:00.000',
    @demo_quality_id,
    '2026-06-22 03:00:00.000'
WHERE NOT EXISTS (
    SELECT 1 FROM customer WHERE customer_code = 'CUS-DEMO-TRACE-001'
);

SET @demo_customer_id = (
    SELECT id FROM customer WHERE customer_code = 'CUS-DEMO-TRACE-001' LIMIT 1
);

INSERT INTO customer_qualification (
    customer_id,
    qualification_type,
    certificate_no,
    issuing_authority,
    issued_on,
    valid_from,
    valid_until,
    status,
    remark,
    created_by,
    created_at,
    updated_by,
    updated_at
)
SELECT
    @demo_customer_id,
    'MEDICAL_INSTITUTION_LICENSE',
    'DEMO-TRACE-CUS-MIL-001',
    '广州市卫生健康委员会（演示）',
    '2025-01-01',
    '2025-01-01',
    '2029-12-31',
    'VALID',
    '固定演示资质',
    @demo_admin_id,
    '2026-06-18 01:10:00.000',
    @demo_quality_id,
    '2026-06-22 03:00:00.000'
WHERE NOT EXISTS (
    SELECT 1
    FROM customer_qualification
    WHERE customer_id = @demo_customer_id
      AND qualification_type = 'MEDICAL_INSTITUTION_LICENSE'
      AND certificate_no = 'DEMO-TRACE-CUS-MIL-001'
);

INSERT INTO customer_qualification (
    customer_id,
    qualification_type,
    certificate_no,
    issuing_authority,
    issued_on,
    valid_from,
    valid_until,
    status,
    remark,
    created_by,
    created_at,
    updated_by,
    updated_at
)
SELECT
    @demo_customer_id,
    'PURCHASE_AUTHORIZATION',
    'DEMO-TRACE-CUS-AUTH-001',
    '广州市演示人民医院（演示）',
    '2026-01-01',
    '2026-01-01',
    '2028-12-31',
    'VALID',
    '固定演示采购授权',
    @demo_admin_id,
    '2026-06-18 01:20:00.000',
    @demo_quality_id,
    '2026-06-22 03:00:00.000'
WHERE NOT EXISTS (
    SELECT 1
    FROM customer_qualification
    WHERE customer_id = @demo_customer_id
      AND qualification_type = 'PURCHASE_AUTHORIZATION'
      AND certificate_no = 'DEMO-TRACE-CUS-AUTH-001'
);

INSERT INTO customer_review (
    review_no,
    customer_id,
    review_round,
    status,
    submitted_by,
    submitted_at,
    reviewer_id,
    reviewed_at,
    review_opinion,
    qualification_snapshot,
    approved_valid_until,
    created_at
)
SELECT
    'DEMO-TRACE-CUS-REV-001',
    @demo_customer_id,
    1,
    'APPROVED',
    @demo_purchaser_id,
    '2026-06-22 01:00:00.000',
    @demo_quality_id,
    '2026-06-22 03:00:00.000',
    '医疗机构执业许可证和采购授权核验通过（演示）',
    JSON_OBJECT(
        'demo', TRUE,
        'qualificationCount', 2,
        'conclusion', 'APPROVED'
    ),
    '2028-12-31',
    '2026-06-22 01:00:00.000'
WHERE NOT EXISTS (
    SELECT 1 FROM customer_review WHERE review_no = 'DEMO-TRACE-CUS-REV-001'
);

SET @demo_customer_review_id = (
    SELECT id FROM customer_review WHERE review_no = 'DEMO-TRACE-CUS-REV-001' LIMIT 1
);

INSERT INTO warehouse (
    warehouse_code,
    warehouse_name,
    department_id,
    manager_user_id,
    address,
    status,
    created_by,
    created_at,
    updated_by,
    updated_at
)
SELECT
    'WH-DEMO-01',
    '广州中心仓（演示）',
    @demo_department_id,
    @demo_admin_id,
    '广东省广州市演示物流园仓储区',
    'ACTIVE',
    @demo_admin_id,
    '2026-06-10 02:00:00.000',
    @demo_admin_id,
    '2026-06-10 02:00:00.000'
WHERE NOT EXISTS (
    SELECT 1 FROM warehouse WHERE warehouse_code = 'WH-DEMO-01'
);

SET @demo_warehouse_id = (
    SELECT id FROM warehouse WHERE warehouse_code = 'WH-DEMO-01' LIMIT 1
);

INSERT INTO warehouse_location (
    warehouse_id,
    location_code,
    location_name,
    location_type,
    status,
    created_by,
    created_at,
    updated_by,
    updated_at
)
SELECT
    @demo_warehouse_id,
    'A01-01',
    '常温合格品 A01-01',
    'NORMAL',
    'ACTIVE',
    @demo_admin_id,
    '2026-06-10 02:10:00.000',
    @demo_admin_id,
    '2026-06-10 02:10:00.000'
WHERE NOT EXISTS (
    SELECT 1
    FROM warehouse_location
    WHERE warehouse_id = @demo_warehouse_id
      AND location_code = 'A01-01'
);

SET @demo_location_id = (
    SELECT id
    FROM warehouse_location
    WHERE warehouse_id = @demo_warehouse_id
      AND location_code = 'A01-01'
    LIMIT 1
);

-- ============================================================================
-- 2. 采购、收货、逐批验收与合格入库
-- ============================================================================

INSERT INTO drug_batch (
    batch_code,
    drug_id,
    manufacturer_id,
    batch_no,
    production_date,
    expiry_date,
    quality_status,
    stock_status,
    created_by,
    created_at,
    updated_by,
    updated_at
)
SELECT
    'BATCH-DEMO-TRACE-001',
    @demo_drug_id,
    @demo_manufacturer_id,
    'DEMO20260701A',
    '2026-06-15',
    '2028-05-31',
    'QUALIFIED',
    'ACTIVE',
    @demo_admin_id,
    '2026-07-03 02:00:00.000',
    @demo_admin_id,
    '2026-07-04 05:00:00.000'
WHERE NOT EXISTS (
    SELECT 1 FROM drug_batch WHERE batch_code = 'BATCH-DEMO-TRACE-001'
);

SET @demo_batch_id = (
    SELECT id FROM drug_batch WHERE batch_code = 'BATCH-DEMO-TRACE-001' LIMIT 1
);

INSERT INTO purchase_order (
    order_no,
    supplier_id,
    supplier_review_id,
    purchaser_id,
    order_date,
    expected_arrival_date,
    status,
    total_amount,
    remark,
    created_by,
    created_at,
    updated_by,
    updated_at
)
SELECT
    'DEMO-PO-TRACE-001',
    @demo_supplier_id,
    @demo_supplier_review_id,
    @demo_purchaser_id,
    '2026-07-01',
    '2026-07-03',
    'COMPLETED',
    9250.00,
    '批号追溯固定演示采购订单',
    @demo_purchaser_id,
    '2026-07-01 01:00:00.000',
    @demo_purchaser_id,
    '2026-07-03 03:00:00.000'
WHERE NOT EXISTS (
    SELECT 1 FROM purchase_order WHERE order_no = 'DEMO-PO-TRACE-001'
);

SET @demo_purchase_order_id = (
    SELECT id FROM purchase_order WHERE order_no = 'DEMO-PO-TRACE-001' LIMIT 1
);

INSERT INTO purchase_order_item (
    purchase_order_id,
    line_no,
    drug_id,
    manufacturer_id,
    batch_no,
    expiry_date,
    ordered_quantity,
    received_quantity,
    unit_price,
    line_amount,
    created_at,
    updated_at
)
SELECT
    @demo_purchase_order_id,
    1,
    @demo_drug_id,
    @demo_manufacturer_id,
    'DEMO20260701A',
    '2028-05-31',
    500.0000,
    500.0000,
    18.5000,
    9250.00,
    '2026-07-01 01:00:00.000',
    '2026-07-03 03:00:00.000'
WHERE NOT EXISTS (
    SELECT 1
    FROM purchase_order_item
    WHERE purchase_order_id = @demo_purchase_order_id
      AND line_no = 1
);

SET @demo_purchase_item_id = (
    SELECT id
    FROM purchase_order_item
    WHERE purchase_order_id = @demo_purchase_order_id
      AND line_no = 1
    LIMIT 1
);

INSERT INTO purchase_order_review (
    purchase_order_id,
    review_round,
    reviewer_id,
    review_result,
    review_opinion,
    reviewed_at
)
SELECT
    @demo_purchase_order_id,
    1,
    @demo_quality_id,
    'APPROVED',
    '供应商和品种准入信息核验通过（演示）',
    '2026-07-01 02:00:00.000'
WHERE NOT EXISTS (
    SELECT 1
    FROM purchase_order_review
    WHERE purchase_order_id = @demo_purchase_order_id
      AND review_round = 1
);

INSERT INTO goods_receipt (
    receipt_no,
    purchase_order_id,
    warehouse_id,
    delivery_document_no,
    received_by,
    received_at,
    status,
    transport_condition,
    remark,
    created_by,
    created_at,
    updated_by,
    updated_at
)
SELECT
    'DEMO-GR-TRACE-001',
    @demo_purchase_order_id,
    @demo_warehouse_id,
    'DEMO-DOC-IN-001',
    @demo_admin_id,
    '2026-07-03 03:00:00.000',
    'COMPLETED',
    'PASS',
    '运输条件、包装和随货同行单检查正常（演示）',
    @demo_admin_id,
    '2026-07-03 02:30:00.000',
    @demo_admin_id,
    '2026-07-03 03:00:00.000'
WHERE NOT EXISTS (
    SELECT 1 FROM goods_receipt WHERE receipt_no = 'DEMO-GR-TRACE-001'
);

SET @demo_receipt_id = (
    SELECT id FROM goods_receipt WHERE receipt_no = 'DEMO-GR-TRACE-001' LIMIT 1
);

INSERT INTO goods_receipt_item (
    goods_receipt_id,
    line_no,
    purchase_order_item_id,
    drug_batch_id,
    received_quantity,
    package_condition,
    information_match,
    discrepancy_description,
    created_at,
    updated_at
)
SELECT
    @demo_receipt_id,
    1,
    @demo_purchase_item_id,
    @demo_batch_id,
    500.0000,
    'PASS',
    1,
    NULL,
    '2026-07-03 03:00:00.000',
    '2026-07-03 03:00:00.000'
WHERE NOT EXISTS (
    SELECT 1
    FROM goods_receipt_item
    WHERE goods_receipt_id = @demo_receipt_id
      AND line_no = 1
);

SET @demo_receipt_item_id = (
    SELECT id
    FROM goods_receipt_item
    WHERE goods_receipt_id = @demo_receipt_id
      AND line_no = 1
    LIMIT 1
);

INSERT INTO acceptance_record (
    acceptance_no,
    goods_receipt_id,
    inspector_id,
    status,
    started_at,
    completed_at,
    overall_conclusion,
    conclusion_remark,
    created_by,
    created_at,
    updated_by,
    updated_at
)
SELECT
    'DEMO-AC-TRACE-001',
    @demo_receipt_id,
    @demo_quality_id,
    'COMPLETED',
    '2026-07-03 03:30:00.000',
    '2026-07-03 04:00:00.000',
    'PASSED',
    '药品信息、数量、包装、批号和有效期逐项验收合格（演示）',
    @demo_quality_id,
    '2026-07-03 03:30:00.000',
    @demo_quality_id,
    '2026-07-03 04:00:00.000'
WHERE NOT EXISTS (
    SELECT 1 FROM acceptance_record WHERE acceptance_no = 'DEMO-AC-TRACE-001'
);

SET @demo_acceptance_id = (
    SELECT id FROM acceptance_record WHERE acceptance_no = 'DEMO-AC-TRACE-001' LIMIT 1
);

INSERT INTO acceptance_record_item (
    acceptance_record_id,
    goods_receipt_item_id,
    drug_batch_id,
    inspected_quantity,
    qualified_quantity,
    unqualified_quantity,
    drug_information_passed,
    quantity_passed,
    package_passed,
    batch_passed,
    expiry_passed,
    result,
    result_description,
    created_at,
    updated_at
)
SELECT
    @demo_acceptance_id,
    @demo_receipt_item_id,
    @demo_batch_id,
    500.0000,
    500.0000,
    0.0000,
    1,
    1,
    1,
    1,
    1,
    'PASSED',
    '逐批验收全部检查项通过（演示）',
    '2026-07-03 04:00:00.000',
    '2026-07-03 04:00:00.000'
WHERE NOT EXISTS (
    SELECT 1
    FROM acceptance_record_item
    WHERE goods_receipt_item_id = @demo_receipt_item_id
);

SET @demo_acceptance_item_id = (
    SELECT id
    FROM acceptance_record_item
    WHERE goods_receipt_item_id = @demo_receipt_item_id
    LIMIT 1
);

INSERT INTO stock_in_order (
    stock_in_no,
    acceptance_record_id,
    warehouse_id,
    status,
    operator_id,
    posted_by,
    posted_at,
    remark,
    created_by,
    created_at,
    updated_by,
    updated_at
)
SELECT
    'DEMO-SI-TRACE-001',
    @demo_acceptance_id,
    @demo_warehouse_id,
    'POSTED',
    @demo_admin_id,
    @demo_admin_id,
    '2026-07-04 05:00:00.000',
    '验收合格后入库过账（演示）',
    @demo_admin_id,
    '2026-07-04 04:30:00.000',
    @demo_admin_id,
    '2026-07-04 05:00:00.000'
WHERE NOT EXISTS (
    SELECT 1 FROM stock_in_order WHERE stock_in_no = 'DEMO-SI-TRACE-001'
);

SET @demo_stock_in_id = (
    SELECT id FROM stock_in_order WHERE stock_in_no = 'DEMO-SI-TRACE-001' LIMIT 1
);

INSERT INTO stock_in_order_item (
    stock_in_order_id,
    line_no,
    acceptance_record_item_id,
    drug_batch_id,
    warehouse_location_id,
    stock_in_quantity,
    created_at
)
SELECT
    @demo_stock_in_id,
    1,
    @demo_acceptance_item_id,
    @demo_batch_id,
    @demo_location_id,
    500.0000,
    '2026-07-04 05:00:00.000'
WHERE NOT EXISTS (
    SELECT 1
    FROM stock_in_order_item
    WHERE stock_in_order_id = @demo_stock_in_id
      AND line_no = 1
);

INSERT INTO inventory_balance (
    drug_batch_id,
    warehouse_id,
    warehouse_location_id,
    total_quantity,
    available_quantity,
    reserved_quantity,
    quarantined_quantity,
    status,
    last_ledger_id,
    created_at,
    updated_at,
    version
)
SELECT
    @demo_batch_id,
    @demo_warehouse_id,
    @demo_location_id,
    0.0000,
    0.0000,
    0.0000,
    0.0000,
    'ACTIVE',
    NULL,
    '2026-07-04 05:00:00.000',
    '2026-07-04 05:00:00.000',
    0
WHERE NOT EXISTS (
    SELECT 1
    FROM inventory_balance
    WHERE drug_batch_id = @demo_batch_id
      AND warehouse_id = @demo_warehouse_id
      AND warehouse_location_id = @demo_location_id
);

SET @demo_balance_id = (
    SELECT id
    FROM inventory_balance
    WHERE drug_batch_id = @demo_batch_id
      AND warehouse_id = @demo_warehouse_id
      AND warehouse_location_id = @demo_location_id
    LIMIT 1
);

INSERT INTO inventory_ledger (
    ledger_no,
    idempotency_key,
    inventory_balance_id,
    drug_batch_id,
    warehouse_id,
    warehouse_location_id,
    transaction_type,
    movement_mode,
    quantity,
    before_total_quantity,
    after_total_quantity,
    before_available_quantity,
    after_available_quantity,
    before_reserved_quantity,
    after_reserved_quantity,
    before_quarantined_quantity,
    after_quarantined_quantity,
    source_business_type,
    source_business_id,
    source_business_no,
    operator_id,
    occurred_at,
    remark
)
SELECT
    'DEMO-LEDGER-IN-001',
    'DEMO:TRACE:STOCK_IN:001',
    @demo_balance_id,
    @demo_batch_id,
    @demo_warehouse_id,
    @demo_location_id,
    'INBOUND',
    'INCREASE',
    500.0000,
    0.0000,
    500.0000,
    0.0000,
    500.0000,
    0.0000,
    0.0000,
    0.0000,
    0.0000,
    'STOCK_IN_ORDER',
    @demo_stock_in_id,
    'DEMO-SI-TRACE-001',
    @demo_admin_id,
    '2026-07-04 05:00:00.000',
    '验收合格数量入库（演示）'
WHERE NOT EXISTS (
    SELECT 1 FROM inventory_ledger WHERE ledger_no = 'DEMO-LEDGER-IN-001'
);

SET @demo_inbound_ledger_id = (
    SELECT id FROM inventory_ledger WHERE ledger_no = 'DEMO-LEDGER-IN-001' LIMIT 1
);

UPDATE inventory_balance
SET
    total_quantity = 500.0000,
    available_quantity = 500.0000,
    reserved_quantity = 0.0000,
    quarantined_quantity = 0.0000,
    last_ledger_id = @demo_inbound_ledger_id,
    updated_at = '2026-07-04 05:00:00.000',
    version = version + 1
WHERE id = @demo_balance_id
  AND last_ledger_id IS NULL;

-- ============================================================================
-- 3. 客户销售、库存占用、独立复核与出库
-- ============================================================================

INSERT INTO sales_order (
    order_no,
    customer_id,
    customer_review_id,
    warehouse_id,
    salesperson_id,
    order_date,
    status,
    total_amount,
    receiver_name,
    receiver_phone,
    delivery_address,
    remark,
    created_by,
    created_at,
    updated_by,
    updated_at
)
SELECT
    'DEMO-SO-TRACE-001',
    @demo_customer_id,
    @demo_customer_review_id,
    @demo_warehouse_id,
    @demo_admin_id,
    '2026-07-06',
    'COMPLETED',
    3216.00,
    '周药师',
    '020-88880003',
    '广东省广州市演示大道 3 号',
    '批号追溯固定演示销售订单',
    @demo_admin_id,
    '2026-07-06 01:00:00.000',
    @demo_admin_id,
    '2026-07-07 03:00:00.000'
WHERE NOT EXISTS (
    SELECT 1 FROM sales_order WHERE order_no = 'DEMO-SO-TRACE-001'
);

SET @demo_sales_order_id = (
    SELECT id FROM sales_order WHERE order_no = 'DEMO-SO-TRACE-001' LIMIT 1
);

INSERT INTO sales_order_item (
    sales_order_id,
    line_no,
    drug_id,
    ordered_quantity,
    allocated_quantity,
    outbound_quantity,
    unit_price,
    line_amount,
    created_at,
    updated_at
)
SELECT
    @demo_sales_order_id,
    1,
    @demo_drug_id,
    120.0000,
    120.0000,
    120.0000,
    26.8000,
    3216.00,
    '2026-07-06 01:00:00.000',
    '2026-07-07 03:00:00.000'
WHERE NOT EXISTS (
    SELECT 1
    FROM sales_order_item
    WHERE sales_order_id = @demo_sales_order_id
      AND line_no = 1
);

SET @demo_sales_item_id = (
    SELECT id
    FROM sales_order_item
    WHERE sales_order_id = @demo_sales_order_id
      AND line_no = 1
    LIMIT 1
);

INSERT INTO sales_order_review (
    sales_order_id,
    review_round,
    reviewer_id,
    review_result,
    review_opinion,
    reviewed_at
)
SELECT
    @demo_sales_order_id,
    1,
    @demo_quality_id,
    'APPROVED',
    '客户资质有效且经营范围符合要求（演示）',
    '2026-07-06 01:30:00.000'
WHERE NOT EXISTS (
    SELECT 1
    FROM sales_order_review
    WHERE sales_order_id = @demo_sales_order_id
      AND review_round = 1
);

INSERT INTO inventory_reservation (
    reservation_no,
    sales_order_item_id,
    inventory_balance_id,
    drug_batch_id,
    reserved_quantity,
    status,
    reserved_by,
    reserved_at,
    consumed_at,
    created_at,
    updated_at
)
SELECT
    'DEMO-RESERVE-TRACE-001',
    @demo_sales_item_id,
    @demo_balance_id,
    @demo_batch_id,
    120.0000,
    'CONSUMED',
    @demo_admin_id,
    '2026-07-06 02:00:00.000',
    '2026-07-07 03:00:00.000',
    '2026-07-06 02:00:00.000',
    '2026-07-07 03:00:00.000'
WHERE NOT EXISTS (
    SELECT 1 FROM inventory_reservation WHERE reservation_no = 'DEMO-RESERVE-TRACE-001'
);

SET @demo_reservation_id = (
    SELECT id
    FROM inventory_reservation
    WHERE reservation_no = 'DEMO-RESERVE-TRACE-001'
    LIMIT 1
);

INSERT INTO inventory_ledger (
    ledger_no,
    idempotency_key,
    inventory_balance_id,
    drug_batch_id,
    warehouse_id,
    warehouse_location_id,
    transaction_type,
    movement_mode,
    quantity,
    before_total_quantity,
    after_total_quantity,
    before_available_quantity,
    after_available_quantity,
    before_reserved_quantity,
    after_reserved_quantity,
    before_quarantined_quantity,
    after_quarantined_quantity,
    source_business_type,
    source_business_id,
    source_business_no,
    operator_id,
    occurred_at,
    remark
)
SELECT
    'DEMO-LEDGER-RESERVE-001',
    'DEMO:TRACE:RESERVE:001',
    @demo_balance_id,
    @demo_batch_id,
    @demo_warehouse_id,
    @demo_location_id,
    'RESERVE',
    'TRANSFER',
    120.0000,
    500.0000,
    500.0000,
    500.0000,
    380.0000,
    0.0000,
    120.0000,
    0.0000,
    0.0000,
    'INVENTORY_RESERVATION',
    @demo_reservation_id,
    'DEMO-RESERVE-TRACE-001',
    @demo_admin_id,
    '2026-07-06 02:00:00.000',
    '为销售订单占用批号库存（演示）'
WHERE NOT EXISTS (
    SELECT 1 FROM inventory_ledger WHERE ledger_no = 'DEMO-LEDGER-RESERVE-001'
);

SET @demo_reserve_ledger_id = (
    SELECT id
    FROM inventory_ledger
    WHERE ledger_no = 'DEMO-LEDGER-RESERVE-001'
    LIMIT 1
);

UPDATE inventory_balance
SET
    total_quantity = 500.0000,
    available_quantity = 380.0000,
    reserved_quantity = 120.0000,
    quarantined_quantity = 0.0000,
    last_ledger_id = @demo_reserve_ledger_id,
    updated_at = '2026-07-06 02:00:00.000',
    version = version + 1
WHERE id = @demo_balance_id
  AND last_ledger_id = @demo_inbound_ledger_id;

INSERT INTO outbound_order (
    outbound_no,
    sales_order_id,
    warehouse_id,
    status,
    prepared_by,
    submitted_for_review_at,
    outbound_by,
    outbound_at,
    delivery_document_no,
    remark,
    created_by,
    created_at,
    updated_by,
    updated_at
)
SELECT
    'DEMO-OB-TRACE-001',
    @demo_sales_order_id,
    @demo_warehouse_id,
    'OUTBOUNDED',
    @demo_admin_id,
    '2026-07-07 01:30:00.000',
    @demo_admin_id,
    '2026-07-07 03:00:00.000',
    'DEMO-DOC-OUT-001',
    '独立复核通过后出库（演示）',
    @demo_admin_id,
    '2026-07-07 01:00:00.000',
    @demo_admin_id,
    '2026-07-07 03:00:00.000'
WHERE NOT EXISTS (
    SELECT 1 FROM outbound_order WHERE outbound_no = 'DEMO-OB-TRACE-001'
);

SET @demo_outbound_id = (
    SELECT id FROM outbound_order WHERE outbound_no = 'DEMO-OB-TRACE-001' LIMIT 1
);

INSERT INTO outbound_order_review (
    outbound_order_id,
    review_round,
    reviewer_id,
    review_result,
    review_opinion,
    reviewed_at
)
SELECT
    @demo_outbound_id,
    1,
    @demo_quality_id,
    'APPROVED',
    '品名、规格、批号、有效期、数量和客户信息复核一致（演示）',
    '2026-07-07 02:00:00.000'
WHERE NOT EXISTS (
    SELECT 1
    FROM outbound_order_review
    WHERE outbound_order_id = @demo_outbound_id
      AND review_round = 1
);

INSERT INTO outbound_order_item (
    outbound_order_id,
    line_no,
    sales_order_item_id,
    inventory_reservation_id,
    inventory_balance_id,
    drug_batch_id,
    warehouse_location_id,
    outbound_quantity,
    created_at
)
SELECT
    @demo_outbound_id,
    1,
    @demo_sales_item_id,
    @demo_reservation_id,
    @demo_balance_id,
    @demo_batch_id,
    @demo_location_id,
    120.0000,
    '2026-07-07 03:00:00.000'
WHERE NOT EXISTS (
    SELECT 1
    FROM outbound_order_item
    WHERE outbound_order_id = @demo_outbound_id
      AND line_no = 1
);

INSERT INTO inventory_ledger (
    ledger_no,
    idempotency_key,
    inventory_balance_id,
    drug_batch_id,
    warehouse_id,
    warehouse_location_id,
    transaction_type,
    movement_mode,
    quantity,
    before_total_quantity,
    after_total_quantity,
    before_available_quantity,
    after_available_quantity,
    before_reserved_quantity,
    after_reserved_quantity,
    before_quarantined_quantity,
    after_quarantined_quantity,
    source_business_type,
    source_business_id,
    source_business_no,
    operator_id,
    occurred_at,
    remark
)
SELECT
    'DEMO-LEDGER-OUT-001',
    'DEMO:TRACE:OUTBOUND:001',
    @demo_balance_id,
    @demo_batch_id,
    @demo_warehouse_id,
    @demo_location_id,
    'OUTBOUND',
    'DECREASE',
    120.0000,
    500.0000,
    380.0000,
    380.0000,
    380.0000,
    120.0000,
    0.0000,
    0.0000,
    0.0000,
    'OUTBOUND_ORDER',
    @demo_outbound_id,
    'DEMO-OB-TRACE-001',
    @demo_admin_id,
    '2026-07-07 03:00:00.000',
    '复核通过后销售出库（演示）'
WHERE NOT EXISTS (
    SELECT 1 FROM inventory_ledger WHERE ledger_no = 'DEMO-LEDGER-OUT-001'
);

SET @demo_outbound_ledger_id = (
    SELECT id FROM inventory_ledger WHERE ledger_no = 'DEMO-LEDGER-OUT-001' LIMIT 1
);

UPDATE inventory_balance
SET
    total_quantity = 380.0000,
    available_quantity = 380.0000,
    reserved_quantity = 0.0000,
    quarantined_quantity = 0.0000,
    last_ledger_id = @demo_outbound_ledger_id,
    updated_at = '2026-07-07 03:00:00.000',
    version = version + 1
WHERE id = @demo_balance_id
  AND last_ledger_id = @demo_reserve_ledger_id;

-- ============================================================================
-- 4. 批号生命周期追溯事件
-- ============================================================================

INSERT INTO batch_trace_event (
    event_no,
    drug_batch_id,
    event_type,
    supplier_id,
    customer_id,
    warehouse_id,
    warehouse_location_id,
    inventory_ledger_id,
    business_type,
    business_id,
    business_no,
    quantity,
    event_data,
    operator_id,
    occurred_at
)
SELECT
    'DEMO-TRACE-01-PURCHASED',
    @demo_batch_id,
    'PURCHASED',
    @demo_supplier_id,
    NULL,
    NULL,
    NULL,
    NULL,
    'PURCHASE_ORDER',
    @demo_purchase_order_id,
    'DEMO-PO-TRACE-001',
    500.0000,
    JSON_OBJECT(
        'demo', TRUE,
        'status', 'APPROVED',
        'unitPrice', 18.5000,
        'lineAmount', 9250.00,
        'reviewResult', 'APPROVED'
    ),
    @demo_purchaser_id,
    '2026-07-01 02:00:00.000'
WHERE NOT EXISTS (
    SELECT 1 FROM batch_trace_event WHERE event_no = 'DEMO-TRACE-01-PURCHASED'
);

INSERT INTO batch_trace_event (
    event_no,
    drug_batch_id,
    event_type,
    supplier_id,
    customer_id,
    warehouse_id,
    warehouse_location_id,
    inventory_ledger_id,
    business_type,
    business_id,
    business_no,
    quantity,
    event_data,
    operator_id,
    occurred_at
)
SELECT
    'DEMO-TRACE-02-RECEIVED',
    @demo_batch_id,
    'RECEIVED',
    @demo_supplier_id,
    NULL,
    @demo_warehouse_id,
    NULL,
    NULL,
    'GOODS_RECEIPT',
    @demo_receipt_id,
    'DEMO-GR-TRACE-001',
    500.0000,
    JSON_OBJECT(
        'demo', TRUE,
        'transportCondition', 'PASS',
        'packageCondition', 'PASS',
        'informationMatch', TRUE,
        'deliveryDocumentNo', 'DEMO-DOC-IN-001'
    ),
    @demo_admin_id,
    '2026-07-03 03:00:00.000'
WHERE NOT EXISTS (
    SELECT 1 FROM batch_trace_event WHERE event_no = 'DEMO-TRACE-02-RECEIVED'
);

INSERT INTO batch_trace_event (
    event_no,
    drug_batch_id,
    event_type,
    supplier_id,
    customer_id,
    warehouse_id,
    warehouse_location_id,
    inventory_ledger_id,
    business_type,
    business_id,
    business_no,
    quantity,
    event_data,
    operator_id,
    occurred_at
)
SELECT
    'DEMO-TRACE-03-ACCEPTED',
    @demo_batch_id,
    'ACCEPTED',
    @demo_supplier_id,
    NULL,
    @demo_warehouse_id,
    NULL,
    NULL,
    'ACCEPTANCE_RECORD',
    @demo_acceptance_id,
    'DEMO-AC-TRACE-001',
    500.0000,
    JSON_OBJECT(
        'demo', TRUE,
        'overallConclusion', 'PASSED',
        'qualifiedQuantity', 500.0000,
        'unqualifiedQuantity', 0.0000,
        'checks', JSON_OBJECT(
            'drugInformation', TRUE,
            'quantity', TRUE,
            'package', TRUE,
            'batch', TRUE,
            'expiry', TRUE
        )
    ),
    @demo_quality_id,
    '2026-07-03 04:00:00.000'
WHERE NOT EXISTS (
    SELECT 1 FROM batch_trace_event WHERE event_no = 'DEMO-TRACE-03-ACCEPTED'
);

INSERT INTO batch_trace_event (
    event_no,
    drug_batch_id,
    event_type,
    supplier_id,
    customer_id,
    warehouse_id,
    warehouse_location_id,
    inventory_ledger_id,
    business_type,
    business_id,
    business_no,
    quantity,
    event_data,
    operator_id,
    occurred_at
)
SELECT
    'DEMO-TRACE-04-STOCKED-IN',
    @demo_batch_id,
    'STOCKED_IN',
    @demo_supplier_id,
    NULL,
    @demo_warehouse_id,
    @demo_location_id,
    @demo_inbound_ledger_id,
    'STOCK_IN_ORDER',
    @demo_stock_in_id,
    'DEMO-SI-TRACE-001',
    500.0000,
    JSON_OBJECT(
        'demo', TRUE,
        'qualityStatus', 'QUALIFIED',
        'stockStatus', 'ACTIVE',
        'balanceAfter', 500.0000,
        'locationCode', 'A01-01'
    ),
    @demo_admin_id,
    '2026-07-04 05:00:00.000'
WHERE NOT EXISTS (
    SELECT 1 FROM batch_trace_event WHERE event_no = 'DEMO-TRACE-04-STOCKED-IN'
);

INSERT INTO batch_trace_event (
    event_no,
    drug_batch_id,
    event_type,
    supplier_id,
    customer_id,
    warehouse_id,
    warehouse_location_id,
    inventory_ledger_id,
    business_type,
    business_id,
    business_no,
    quantity,
    event_data,
    operator_id,
    occurred_at
)
SELECT
    'DEMO-TRACE-05-RESERVED',
    @demo_batch_id,
    'RESERVED',
    NULL,
    @demo_customer_id,
    @demo_warehouse_id,
    @demo_location_id,
    @demo_reserve_ledger_id,
    'INVENTORY_RESERVATION',
    @demo_reservation_id,
    'DEMO-RESERVE-TRACE-001',
    120.0000,
    JSON_OBJECT(
        'demo', TRUE,
        'salesOrderNo', 'DEMO-SO-TRACE-001',
        'customerCode', 'CUS-DEMO-TRACE-001',
        'availableAfter', 380.0000,
        'reservedAfter', 120.0000
    ),
    @demo_admin_id,
    '2026-07-06 02:00:00.000'
WHERE NOT EXISTS (
    SELECT 1 FROM batch_trace_event WHERE event_no = 'DEMO-TRACE-05-RESERVED'
);

INSERT INTO batch_trace_event (
    event_no,
    drug_batch_id,
    event_type,
    supplier_id,
    customer_id,
    warehouse_id,
    warehouse_location_id,
    inventory_ledger_id,
    business_type,
    business_id,
    business_no,
    quantity,
    event_data,
    operator_id,
    occurred_at
)
SELECT
    'DEMO-TRACE-06-OUTBOUNDED',
    @demo_batch_id,
    'OUTBOUNDED',
    NULL,
    @demo_customer_id,
    @demo_warehouse_id,
    @demo_location_id,
    @demo_outbound_ledger_id,
    'OUTBOUND_ORDER',
    @demo_outbound_id,
    'DEMO-OB-TRACE-001',
    120.0000,
    JSON_OBJECT(
        'demo', TRUE,
        'reviewResult', 'APPROVED',
        'deliveryDocumentNo', 'DEMO-DOC-OUT-001',
        'customerCode', 'CUS-DEMO-TRACE-001',
        'outboundQuantity', 120.0000,
        'balanceAfter', 380.0000
    ),
    @demo_admin_id,
    '2026-07-07 03:00:00.000'
WHERE NOT EXISTS (
    SELECT 1 FROM batch_trace_event WHERE event_no = 'DEMO-TRACE-06-OUTBOUNDED'
);

INSERT INTO sys_operation_log (
    request_id,
    operator_id,
    module_code,
    operation_type,
    business_type,
    business_id,
    operation_summary,
    before_data,
    after_data,
    success,
    failure_reason,
    client_ip,
    user_agent,
    occurred_at
)
SELECT
    'DEMO-TRACE-SEED-001',
    @demo_admin_id,
    'TRACE',
    'DEMO_SEED',
    'DRUG_BATCH',
    @demo_batch_id,
    '写入批号追溯固定演示数据',
    NULL,
    JSON_OBJECT(
        'demo', TRUE,
        'batchNo', 'DEMO20260701A',
        'drugCode', 'DRUG-DEMO-001',
        'eventCount', 6,
        'currentQuantity', 380.0000
    ),
    1,
    NULL,
    '127.0.0.1',
    'Codex demo seed',
    '2026-08-05 13:00:00.000'
WHERE NOT EXISTS (
    SELECT 1 FROM sys_operation_log WHERE request_id = 'DEMO-TRACE-SEED-001'
);

COMMIT;

-- 执行后断言：应返回 1 个批次、1 个库存位置、3 笔流水和 6 个追溯事件。
SELECT
    db.batch_no,
    d.drug_code,
    d.generic_name,
    db.quality_status,
    db.stock_status,
    ib.total_quantity,
    ib.available_quantity,
    COUNT(DISTINCT il.id) AS ledger_count,
    COUNT(DISTINCT e.id) AS trace_event_count
FROM drug_batch db
INNER JOIN drug d ON d.id = db.drug_id
INNER JOIN inventory_balance ib ON ib.drug_batch_id = db.id
LEFT JOIN inventory_ledger il ON il.drug_batch_id = db.id
LEFT JOIN batch_trace_event e ON e.drug_batch_id = db.id
WHERE db.batch_code = 'BATCH-DEMO-TRACE-001'
GROUP BY
    db.batch_no,
    d.drug_code,
    d.generic_name,
    db.quality_status,
    db.stock_status,
    ib.total_quantity,
    ib.available_quantity;

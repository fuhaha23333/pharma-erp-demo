#!/usr/bin/env bash

set -euo pipefail

readonly EXPECTED_SCHEMA='pharma_erp_db_base_01_test'
readonly SCHEMA='pharma_erp_db_base_01_test'
readonly TEST_PREFIX='__DB_BASE_01_TEST__'
readonly REQUIRED_SQL_MODES='ONLY_FULL_GROUP_BY STRICT_TRANS_TABLES NO_ZERO_IN_DATE NO_ZERO_DATE ERROR_FOR_DIVISION_BY_ZERO NO_ENGINE_SUBSTITUTION'

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(CDPATH= cd -- "${SCRIPT_DIR}/.." && pwd)"
readonly SCRIPT_PATH="${SCRIPT_DIR}/verify_db_base_01.sh"
readonly DDL_FILE="${REPO_ROOT}/sql/db-base-01/001_create_system_permission_tables.sql"
readonly SEED_FILE="${REPO_ROOT}/sql/db-base-01/002_seed_system_permission_data.sql"
readonly POM_FILE="${REPO_ROOT}/backend/pom.xml"

LOGIN_PATH="${DB_BASE_01_MYSQL_LOGIN_PATH:-}"
DROP_CONFIRMATION="${DB_BASE_01_CONFIRM_DROP:-}"
schema_created=0
EXPECTED_FAILURE_LOG=''
HASH_TOOL=''

die() {
  printf 'DB-BASE-01 verification failed: %s\n' "$*" >&2
  exit 1
}

on_exit() {
  local rc=$?

  trap - EXIT

  if [[ -n "${EXPECTED_FAILURE_LOG}" && -f "${EXPECTED_FAILURE_LOG}" ]]; then
    rm -f -- "${EXPECTED_FAILURE_LOG}"
  fi

  if [[ "${rc}" -ne 0 && "${schema_created}" -eq 1 ]]; then
    printf 'Validation failed; retained test Schema for inspection: %s\n' "${SCHEMA}" >&2
    printf \
      "Safe inspection command: mysql --no-defaults --login-path=%s --skip-reconnect --database=%s --execute='SHOW TABLES;'\n" \
      "${LOGIN_PATH}" \
      "${SCHEMA}" \
      >&2
  fi

  exit "${rc}"
}

trap on_exit EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
trap 'exit 129' HUP

assert_eq() {
  local expected="$1"
  local actual="$2"
  local label="$3"

  if [[ "${actual}" != "${expected}" ]]; then
    printf 'Assertion failed: %s\nExpected:\n%s\nActual:\n%s\n' \
      "${label}" "${expected}" "${actual}" >&2
    exit 1
  fi
}

assert_zero() {
  local actual="$1"
  local label="$2"
  assert_eq '0' "${actual}" "${label}"
}

assert_drop_guard() {
  [[ "${SCHEMA}" == "${EXPECTED_SCHEMA}" ]] \
    || die 'internal Schema name does not match the fixed DB-BASE-01 test Schema'
  [[ "${SCHEMA}" != 'pharma_erp' ]] \
    || die 'operation on pharma_erp is prohibited'
  [[ "${DROP_CONFIRMATION}" == "${EXPECTED_SCHEMA}" ]] \
    || die 'DB_BASE_01_CONFIRM_DROP must exactly match the fixed test Schema'
}

assert_file_not_match() {
  local file="$1"
  local pattern="$2"
  local label="$3"
  local grep_status

  if grep -Eiq -- "${pattern}" "${file}"; then
    die "${label}"
  else
    grep_status=$?
    case "${grep_status}" in
      1)
        return 0
        ;;
      *)
        die "${label}: grep failed with exit status ${grep_status}"
        ;;
    esac
  fi
}

assert_file_match() {
  local file="$1"
  local pattern="$2"
  local label="$3"
  local grep_status

  if grep -Eiq -- "${pattern}" "${file}"; then
    return 0
  else
    grep_status=$?
    case "${grep_status}" in
      1)
        die "${label}"
        ;;
      *)
        die "${label}: grep failed with exit status ${grep_status}"
        ;;
    esac
  fi
}

choose_hash_tool() {
  if command -v shasum >/dev/null 2>&1; then
    HASH_TOOL='shasum'
  elif command -v sha256sum >/dev/null 2>&1; then
    HASH_TOOL='sha256sum'
  else
    die 'shasum or sha256sum is required for canonical seed verification'
  fi
}

sha256_stdin() {
  if [[ "${HASH_TOOL}" == 'shasum' ]]; then
    shasum -a 256 | awk '{ print $1 }'
  else
    sha256sum | awk '{ print $1 }'
  fi
}

sha256_text() {
  local payload="$1"
  printf '%s\n' "${payload}" | sha256_stdin
}

[[ -n "${LOGIN_PATH}" ]] \
  || die 'DB_BASE_01_MYSQL_LOGIN_PATH is required'
[[ "${LOGIN_PATH}" =~ ^[A-Za-z0-9_.-]+$ ]] \
  || die 'DB_BASE_01_MYSQL_LOGIN_PATH contains unsafe characters'
[[ "${DROP_CONFIRMATION}" == "${EXPECTED_SCHEMA}" ]] \
  || die 'DB_BASE_01_CONFIRM_DROP must exactly match pharma_erp_db_base_01_test'
assert_drop_guard

command -v mysql >/dev/null 2>&1 \
  || die 'mysql client is required'
command -v mvn >/dev/null 2>&1 \
  || die 'Maven is required for backend regression checks'
[[ -r "${DDL_FILE}" ]] \
  || die '001_create_system_permission_tables.sql is missing or unreadable'
[[ -r "${SEED_FILE}" ]] \
  || die '002_seed_system_permission_data.sql is missing or unreadable'
[[ -r "${POM_FILE}" ]] \
  || die 'backend/pom.xml is missing or unreadable'

choose_hash_tool

EXPECTED_FAILURE_LOG="$(mktemp "${TMPDIR:-/tmp}/db-base-01-expected-failure.XXXXXX")"
[[ -f "${EXPECTED_FAILURE_LOG}" ]] \
  || die 'failed to allocate temporary expected-failure log'

readonly -a MYSQL_BASE=(
  mysql
  --no-defaults
  "--login-path=${LOGIN_PATH}"
  --skip-reconnect
  --batch
  --raw
  --skip-column-names
  --silent
  --skip-auto-rehash
  --default-character-set=utf8mb4
  "--init-command=SET SESSION time_zone = '+00:00'"
)

mysql_server() {
  "${MYSQL_BASE[@]}" "$@"
}

mysql_db() {
  "${MYSQL_BASE[@]}" "--database=${SCHEMA}" "$@"
}

query_server() {
  local sql="$1"
  mysql_server --execute "${sql}"
}

query_db() {
  local sql="$1"
  mysql_db --execute "${sql}"
}

assert_db_session() {
  local actual

  actual="$(query_db 'SELECT DATABASE();')"
  assert_eq "${SCHEMA}" "${actual}" 'current database must be the fixed test Schema'

  actual="$(query_db 'SELECT @@SESSION.time_zone;')"
  assert_eq '+00:00' "${actual}" 'session time zone'

  actual="$(query_db 'SELECT @@SESSION.foreign_key_checks;')"
  assert_eq '1' "${actual}" 'foreign_key_checks must remain enabled'
}

expect_mysql_failure() {
  local label="$1"
  local expected_error="$2"
  local sql="$3"
  local invariant_sql="$4"
  local expected_invariant="$5"
  local rc
  local actual_invariant
  local observed_error

  : > "${EXPECTED_FAILURE_LOG}"

  set +e
  mysql_db --execute "${sql}" > /dev/null 2> "${EXPECTED_FAILURE_LOG}"
  rc=$?
  set -e

  if [[ "${rc}" -eq 0 ]]; then
    die "${label}: statement unexpectedly succeeded"
  fi

  if ! grep -Fq -- "${expected_error}" "${EXPECTED_FAILURE_LOG}"; then
    observed_error="$(
      awk '
        match($0, /ERROR [0-9]+/) {
          print substr($0, RSTART, RLENGTH)
          exit
        }
      ' "${EXPECTED_FAILURE_LOG}"
    )"
    die "${label}: expected ${expected_error}, observed ${observed_error:-unknown error}"
  fi

  actual_invariant="$(query_db "${invariant_sql}")"
  assert_eq "${expected_invariant}" "${actual_invariant}" \
    "${label}: data invariant after expected failure"
}

assert_static_sql_boundaries() {
  local seed_flat
  local seed_insert_targets
  local expected_seed_insert_targets
  local forbidden_password_option
  local forbidden_mysql_pwd
  local forbidden_login_dump
  local forbidden_trace
  local forbidden_private_key

  assert_file_not_match \
    "${DDL_FILE}" \
    'CREATE[[:space:]]+(DATABASE|SCHEMA)|DROP[[:space:]]+(DATABASE|SCHEMA)|USE[[:space:]]+' \
    'DDL must not create, drop, or select a Schema'
  assert_file_not_match \
    "${DDL_FILE}" \
    'INSERT[[:space:]]+INTO|INSERT[[:space:]]+IGNORE|REPLACE[[:space:]]+INTO|ON[[:space:]]+DUPLICATE[[:space:]]+KEY[[:space:]]+UPDATE' \
    'DDL must not contain seed DML or duplicate-masking DML'
  assert_file_not_match \
    "${DDL_FILE}" \
    'IF[[:space:]]+NOT[[:space:]]+EXISTS|FOREIGN_KEY_CHECKS[[:space:]]*=[[:space:]]*0|ON[[:space:]]+(DELETE|UPDATE)[[:space:]]+CASCADE' \
    'DDL contains a prohibited idempotency, foreign-key, or CASCADE construct'
  assert_file_not_match \
    "${DDL_FILE}" \
    'CREATE[[:space:]]+(TRIGGER|PROCEDURE|FUNCTION|VIEW|EVENT)|[[:space:]]ENUM[[:space:]]*\(' \
    'DDL contains an unauthorized database object or ENUM'
  assert_file_match \
    "${DDL_FILE}" \
    "SET[[:space:]]+(SESSION[[:space:]]+)?time_zone[[:space:]]*=[[:space:]]*'\\+00:00'" \
    'DDL must explicitly set or verify the +00:00 session time zone'

  assert_file_not_match \
    "${SEED_FILE}" \
    'INSERT[[:space:]]+IGNORE|REPLACE[[:space:]]+INTO|ON[[:space:]]+DUPLICATE[[:space:]]+KEY[[:space:]]+UPDATE' \
    'seed SQL contains duplicate-masking DML'
  assert_file_not_match \
    "${SEED_FILE}" \
    'CREATE[[:space:]]+(DATABASE|SCHEMA)|DROP[[:space:]]+(DATABASE|SCHEMA)|USE[[:space:]]+' \
    'seed SQL must not create, drop, or select a Schema'
  assert_file_not_match \
    "${SEED_FILE}" \
    'FOREIGN_KEY_CHECKS[[:space:]]*=[[:space:]]*0' \
    'seed SQL must not disable foreign_key_checks'

  seed_flat="$(tr '\n' ' ' < "${SEED_FILE}")"
  if ! seed_insert_targets="$(
    printf '%s\n' "${seed_flat}" \
      | grep -Eio -- 'INSERT[[:space:]]+INTO[[:space:]]+`?[a-z0-9_]+`?' \
      | tr '[:lower:]' '[:upper:]' \
      | sed -E 's/^INSERT[[:space:]]+INTO[[:space:]]+`?//; s/`$//' \
      | sort -u
  )"; then
    die 'seed SQL must contain the three authorized explicit INSERT targets'
  fi
  expected_seed_insert_targets="$(
    cat <<'EXPECTED'
SYS_PERMISSION
SYS_ROLE
SYS_ROLE_PERMISSION
EXPECTED
  )"
  assert_eq "${expected_seed_insert_targets}" "${seed_insert_targets}" \
    'seed SQL INSERT targets must be exactly sys_role, sys_permission, and sys_role_permission'

  if printf '%s\n' "${seed_flat}" \
    | grep -Eiq -- 'INSERT[[:space:]]+INTO[[:space:]]+`?sys_user`?([[:space:]]*\(|[[:space:]]+)'; then
    die 'seed SQL must not insert sys_user rows'
  fi
  if printf '%s\n' "${seed_flat}" \
    | grep -Eiq -- 'INSERT[[:space:]]+INTO[[:space:]]+`?sys_user_role`?([[:space:]]*\(|[[:space:]]+)'; then
    die 'seed SQL must not insert sys_user_role rows'
  fi
  if printf '%s\n' "${seed_flat}" \
    | grep -Eiq -- 'INSERT[[:space:]]+INTO[[:space:]]+`?sys_role_assignment`?([[:space:]]*\(|[[:space:]]+)'; then
    die 'seed SQL must not insert sys_role_assignment rows'
  fi
  if printf '%s\n' "${seed_flat}" \
    | grep -Eiq -- 'password_hash|plain_password|(^|[^[:alnum:]_])password([^[:alnum:]_]|$)'; then
    die 'seed SQL must not contain password data'
  fi

  forbidden_password_option='--pass''word'
  forbidden_mysql_pwd='MYSQL_''PWD'
  forbidden_login_dump='mysql_config_''editor print --all'
  forbidden_trace='set -''x'
  forbidden_private_key='-----BEGIN ''PRIVATE KEY-----'

  if grep -Fq -- "${forbidden_password_option}" \
    "${DDL_FILE}" "${SEED_FILE}" "${SCRIPT_PATH}"; then
    die 'implementation files must not contain a command-line password option'
  fi
  if grep -Fq -- "${forbidden_mysql_pwd}" \
    "${DDL_FILE}" "${SEED_FILE}" "${SCRIPT_PATH}"; then
    die 'implementation files must not use the MySQL password environment variable'
  fi
  if grep -Fq -- "${forbidden_login_dump}" \
    "${DDL_FILE}" "${SEED_FILE}" "${SCRIPT_PATH}"; then
    die 'implementation files must not print login-path contents'
  fi
  if grep -Fq -- "${forbidden_trace}" "${SCRIPT_PATH}"; then
    die 'verification script must not enable shell tracing'
  fi
  if grep -Fq -- "${forbidden_private_key}" \
    "${DDL_FILE}" "${SEED_FILE}" "${SCRIPT_PATH}"; then
    die 'implementation files must not contain a private key'
  fi
}

assert_server_prerequisites() {
  local version
  local sql_mode
  local required_mode
  local time_zone
  local foreign_key_checks

  version="$(query_server 'SELECT VERSION();')"
  [[ "${version}" =~ ^8\.4\. ]] \
    || die "MySQL server must be 8.4.x; observed ${version}"

  sql_mode="$(query_server 'SELECT @@SESSION.sql_mode;')"
  for required_mode in ${REQUIRED_SQL_MODES}; do
    if [[ ",${sql_mode}," != *",${required_mode},"* ]]; then
      die "required SQL Mode is missing: ${required_mode}"
    fi
  done

  time_zone="$(query_server 'SELECT @@SESSION.time_zone;')"
  assert_eq '+00:00' "${time_zone}" 'server verification session time zone'

  foreign_key_checks="$(query_server 'SELECT @@SESSION.foreign_key_checks;')"
  assert_eq '1' "${foreign_key_checks}" \
    'server verification session foreign_key_checks'
}

rebuild_empty_schema() {
  local existing

  existing="$(
    query_server \
      "SELECT COUNT(*) FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME = '${EXPECTED_SCHEMA}';"
  )"

  if [[ "${existing}" == '1' ]]; then
    schema_created=1
    assert_drop_guard
    query_server "DROP DATABASE \`${SCHEMA}\`;" > /dev/null
    schema_created=0
  elif [[ "${existing}" != '0' ]]; then
    die 'unexpected fixed-Schema metadata count'
  fi

  assert_drop_guard
  query_server \
    "CREATE DATABASE \`${SCHEMA}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;" \
    > /dev/null
  schema_created=1
}

assert_schema_and_tables() {
  local actual
  local expected

  actual="$(
    query_server "
      SELECT CONCAT(DEFAULT_CHARACTER_SET_NAME, '|', DEFAULT_COLLATION_NAME)
      FROM INFORMATION_SCHEMA.SCHEMATA
      WHERE SCHEMA_NAME = '${SCHEMA}';
    "
  )"
  assert_eq 'utf8mb4|utf8mb4_0900_ai_ci' "${actual}" \
    'Schema character set and collation'

  expected="$(
    cat <<'EXPECTED'
sys_permission|BASE TABLE|InnoDB
sys_role|BASE TABLE|InnoDB
sys_role_assignment|BASE TABLE|InnoDB
sys_role_permission|BASE TABLE|InnoDB
sys_user|BASE TABLE|InnoDB
sys_user_role|BASE TABLE|InnoDB
EXPECTED
  )"
  actual="$(
    query_server "
      SELECT CONCAT(TABLE_NAME, '|', TABLE_TYPE, '|', ENGINE)
      FROM INFORMATION_SCHEMA.TABLES
      WHERE TABLE_SCHEMA = '${SCHEMA}'
      ORDER BY TABLE_NAME;
    "
  )"
  assert_eq "${expected}" "${actual}" \
    'exact six-table set, table type, and engine'

  actual="$(
    query_server "
      SELECT
        (SELECT COUNT(*) FROM INFORMATION_SCHEMA.VIEWS
          WHERE TABLE_SCHEMA = '${SCHEMA}')
        +
        (SELECT COUNT(*) FROM INFORMATION_SCHEMA.TRIGGERS
          WHERE TRIGGER_SCHEMA = '${SCHEMA}')
        +
        (SELECT COUNT(*) FROM INFORMATION_SCHEMA.ROUTINES
          WHERE ROUTINE_SCHEMA = '${SCHEMA}')
        +
        (SELECT COUNT(*) FROM INFORMATION_SCHEMA.EVENTS
          WHERE EVENT_SCHEMA = '${SCHEMA}');
    "
  )"
  assert_zero "${actual}" 'no views, triggers, routines, or events in test Schema'
}

assert_column_definitions() {
  local actual
  local actual_hash
  local column_count
  local varchar_mismatches
  # Canonical SHA-256 of all 77 Section 9 column rows after the normalization
  # performed by the INFORMATION_SCHEMA query below.
  local expected_hash='d673e77d54b1b0abb0ba22c4604d229a5167a7806909cf9e95c1df187184a3bb'

  column_count="$(
    query_server "
      SELECT COUNT(*)
      FROM INFORMATION_SCHEMA.COLUMNS
      WHERE TABLE_SCHEMA = '${SCHEMA}';
    "
  )"
  assert_eq '77' "${column_count}" 'total physical column count'

  actual="$(
    query_server "
      SELECT CONCAT_WS(
        CHAR(9),
        TABLE_NAME,
        ORDINAL_POSITION,
        COLUMN_NAME,
        DATA_TYPE,
        COALESCE(CAST(CHARACTER_MAXIMUM_LENGTH AS CHAR), '-'),
        COALESCE(CAST(DATETIME_PRECISION AS CHAR), '-'),
        IS_NULLABLE,
        COALESCE(
          CASE
            WHEN LOWER(CAST(COLUMN_DEFAULT AS CHAR)) LIKE 'current_timestamp%'
              THEN UPPER(CAST(COLUMN_DEFAULT AS CHAR))
            ELSE CAST(COLUMN_DEFAULT AS CHAR)
          END,
          '<NULL>'
        ),
        IF(LOCATE('auto_increment', LOWER(EXTRA)) > 0, 'AUTO_INCREMENT', '-'),
        IF(
          LOCATE('on update current_timestamp(3)', LOWER(EXTRA)) > 0,
          'ON_UPDATE_CURRENT_TIMESTAMP_3',
          '-'
        )
      )
      FROM INFORMATION_SCHEMA.COLUMNS
      WHERE TABLE_SCHEMA = '${SCHEMA}'
      ORDER BY TABLE_NAME, ORDINAL_POSITION;
    "
  )"
  actual_hash="$(sha256_text "${actual}")"
  assert_eq "${expected_hash}" "${actual_hash}" \
    'all 77 column names, order, types, lengths, precision, NULL rules, defaults, and update behavior'

  varchar_mismatches="$(
    query_server "
      SELECT COUNT(*)
      FROM INFORMATION_SCHEMA.COLUMNS
      WHERE TABLE_SCHEMA = '${SCHEMA}'
        AND DATA_TYPE = 'varchar'
        AND (
          CHARACTER_SET_NAME <> 'utf8mb4'
          OR COLLATION_NAME <> 'utf8mb4_0900_ai_ci'
        );
    "
  )"
  assert_zero "${varchar_mismatches}" \
    'all VARCHAR columns must use utf8mb4_0900_ai_ci'
}

assert_primary_keys() {
  local expected
  local actual
  local table
  local show_index
  local show_count

  expected="$(
    cat <<'EXPECTED'
sys_permission|PRIMARY|id
sys_role|PRIMARY|id
sys_role_assignment|PRIMARY|id
sys_role_permission|PRIMARY|id
sys_user|PRIMARY|id
sys_user_role|PRIMARY|id
EXPECTED
  )"
  actual="$(
    query_server "
      SELECT CONCAT(
        TABLE_NAME,
        '|',
        INDEX_NAME,
        '|',
        GROUP_CONCAT(COLUMN_NAME ORDER BY SEQ_IN_INDEX SEPARATOR ',')
      )
      FROM INFORMATION_SCHEMA.STATISTICS
      WHERE TABLE_SCHEMA = '${SCHEMA}'
        AND INDEX_NAME = 'PRIMARY'
      GROUP BY TABLE_NAME, INDEX_NAME
      ORDER BY TABLE_NAME;
    "
  )"
  assert_eq "${expected}" "${actual}" \
    'INFORMATION_SCHEMA primary keys must be PRIMARY(id)'

  for table in \
    sys_user \
    sys_role \
    sys_permission \
    sys_role_assignment \
    sys_user_role \
    sys_role_permission; do
    show_index="$(query_db "SHOW INDEX FROM \`${table}\` WHERE Key_name = 'PRIMARY';")"
    show_count="$(
      printf '%s\n' "${show_index}" \
        | awk -F '\t' '$3 == "PRIMARY" && $4 == "1" && $5 == "id" { count++ }
          END { print count + 0 }'
    )"
    assert_eq '1' "${show_count}" \
      "SHOW INDEX PRIMARY(id) for ${table}"
  done

  actual="$(
    query_server "
      SELECT COUNT(*)
      FROM INFORMATION_SCHEMA.STATISTICS
      WHERE TABLE_SCHEMA = '${SCHEMA}'
        AND LEFT(INDEX_NAME, 7) = 'pk_sys_';
    "
  )"
  assert_zero "${actual}" 'pk_sys_* must not exist as physical MySQL index names'
}

assert_unique_constraints() {
  local expected
  local actual

  expected="$(
    cat <<'EXPECTED'
sys_permission|uk_sys_permission_code|permission_code
sys_role|uk_sys_role_code|role_code
sys_role|uk_sys_role_name|role_name
sys_role_assignment|uk_sys_role_assignment_no|assignment_no
sys_role_permission|uk_sys_role_permission|role_id,permission_id
sys_user|uk_sys_user_username|username
sys_user_role|uk_sys_user_role|user_id,role_id
sys_user_role|uk_sys_user_role_source_assignment|source_assignment_id
EXPECTED
  )"
  actual="$(
    query_server "
      SELECT CONCAT(
        tc.TABLE_NAME,
        '|',
        tc.CONSTRAINT_NAME,
        '|',
        GROUP_CONCAT(kcu.COLUMN_NAME ORDER BY kcu.ORDINAL_POSITION SEPARATOR ',')
      )
      FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS tc
      JOIN INFORMATION_SCHEMA.KEY_COLUMN_USAGE kcu
        ON kcu.CONSTRAINT_SCHEMA = tc.CONSTRAINT_SCHEMA
       AND kcu.TABLE_NAME = tc.TABLE_NAME
       AND kcu.CONSTRAINT_NAME = tc.CONSTRAINT_NAME
      WHERE tc.CONSTRAINT_SCHEMA = '${SCHEMA}'
        AND tc.CONSTRAINT_TYPE = 'UNIQUE'
      GROUP BY tc.TABLE_NAME, tc.CONSTRAINT_NAME
      ORDER BY tc.TABLE_NAME, tc.CONSTRAINT_NAME;
    "
  )"
  assert_eq "${expected}" "${actual}" \
    'exact eight named unique constraints and columns'
}

assert_check_constraints() {
  local expected
  local actual

  expected="$(
    cat <<'EXPECTED'
sys_permission|ck_sys_permission_execution_mode|YES
sys_permission|ck_sys_permission_is_builtin|YES
sys_permission|ck_sys_permission_module|YES
sys_role|ck_sys_role_is_builtin|YES
sys_role|ck_sys_role_risk_level|YES
sys_role|ck_sys_role_status|YES
sys_role_assignment|ck_sys_role_assignment_approval|YES
sys_role_assignment|ck_sys_role_assignment_approve_pair|YES
sys_role_assignment|ck_sys_role_assignment_approve_sod|YES
sys_role_assignment|ck_sys_role_assignment_creator|YES
sys_role_assignment|ck_sys_role_assignment_execute_pair|YES
sys_role_assignment|ck_sys_role_assignment_execute_sod|YES
sys_role_assignment|ck_sys_role_assignment_review_approve_sod|YES
sys_role_assignment|ck_sys_role_assignment_review_pair|YES
sys_role_assignment|ck_sys_role_assignment_review_sod|YES
sys_role_assignment|ck_sys_role_assignment_status|YES
sys_role_assignment|ck_sys_role_assignment_type|YES
sys_role_assignment|ck_sys_role_assignment_valid_period|YES
sys_user|ck_sys_user_display_name_nonblank|YES
sys_user|ck_sys_user_password_hash_nonblank|YES
sys_user|ck_sys_user_status|YES
sys_user|ck_sys_user_username_nonblank|YES
sys_user_role|ck_sys_user_role_status|YES
sys_user_role|ck_sys_user_role_valid_period|YES
EXPECTED
  )"
  actual="$(
    query_server "
      SELECT CONCAT(TABLE_NAME, '|', CONSTRAINT_NAME, '|', ENFORCED)
      FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
      WHERE CONSTRAINT_SCHEMA = '${SCHEMA}'
        AND CONSTRAINT_TYPE = 'CHECK'
      ORDER BY TABLE_NAME, CONSTRAINT_NAME;
    "
  )"
  assert_eq "${expected}" "${actual}" \
    'exact 24 named and enforced CHECK constraints'
}

assert_explicit_indexes() {
  local expected
  local actual
  local unsupported_fks
  local unexpected_indexes

  expected="$(
    cat <<'EXPECTED'
sys_permission|idx_sys_permission_mode|execution_mode
sys_permission|idx_sys_permission_module|module_code
sys_role|idx_sys_role_status|status
sys_role_assignment|idx_sys_role_assignment_role_status|role_id,status
sys_role_assignment|idx_sys_role_assignment_status_requested|status,requested_at
sys_role_assignment|idx_sys_role_assignment_target_status|target_user_id,status
sys_role_permission|idx_sys_role_permission_permission|permission_id
sys_user|idx_sys_user_status|status
sys_user_role|idx_sys_user_role_role_status|role_id,status,valid_to
sys_user_role|idx_sys_user_role_user_status|user_id,status,valid_to
EXPECTED
  )"
  actual="$(
    query_server "
      SELECT CONCAT(
        TABLE_NAME,
        '|',
        INDEX_NAME,
        '|',
        GROUP_CONCAT(COLUMN_NAME ORDER BY SEQ_IN_INDEX SEPARATOR ',')
      )
      FROM INFORMATION_SCHEMA.STATISTICS
      WHERE TABLE_SCHEMA = '${SCHEMA}'
        AND LEFT(INDEX_NAME, 4) = 'idx_'
        AND NON_UNIQUE = 1
      GROUP BY TABLE_NAME, INDEX_NAME
      ORDER BY TABLE_NAME, INDEX_NAME;
    "
  )"
  assert_eq "${expected}" "${actual}" \
    'exact ten explicitly named ordinary indexes and columns'

  unsupported_fks="$(
    query_server "
      WITH fk_columns AS (
        SELECT
          TABLE_NAME,
          CONSTRAINT_NAME,
          GROUP_CONCAT(COLUMN_NAME ORDER BY ORDINAL_POSITION SEPARATOR ',')
            AS column_names
        FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
        WHERE CONSTRAINT_SCHEMA = '${SCHEMA}'
          AND REFERENCED_TABLE_NAME IS NOT NULL
        GROUP BY TABLE_NAME, CONSTRAINT_NAME
      ),
      index_columns AS (
        SELECT
          TABLE_NAME,
          INDEX_NAME,
          GROUP_CONCAT(COLUMN_NAME ORDER BY SEQ_IN_INDEX SEPARATOR ',')
            AS column_names
        FROM INFORMATION_SCHEMA.STATISTICS
        WHERE TABLE_SCHEMA = '${SCHEMA}'
        GROUP BY TABLE_NAME, INDEX_NAME
      )
      SELECT COUNT(*)
      FROM fk_columns fk
      WHERE NOT EXISTS (
        SELECT 1
        FROM index_columns idx
        WHERE idx.TABLE_NAME = fk.TABLE_NAME
          AND (
            idx.column_names = fk.column_names
            OR idx.column_names LIKE CONCAT(fk.column_names, ',%')
          )
      );
    "
  )"
  assert_zero "${unsupported_fks}" \
    'every foreign key must have a supporting left-prefix index'

  unexpected_indexes="$(
    query_server "
      SELECT COUNT(*)
      FROM (
        SELECT DISTINCT s.TABLE_NAME, s.INDEX_NAME
        FROM INFORMATION_SCHEMA.STATISTICS s
        LEFT JOIN INFORMATION_SCHEMA.TABLE_CONSTRAINTS tc
          ON tc.CONSTRAINT_SCHEMA = s.TABLE_SCHEMA
         AND tc.TABLE_NAME = s.TABLE_NAME
         AND tc.CONSTRAINT_NAME = s.INDEX_NAME
         AND tc.CONSTRAINT_TYPE IN ('PRIMARY KEY', 'UNIQUE')
        LEFT JOIN INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS rc
          ON rc.CONSTRAINT_SCHEMA = s.TABLE_SCHEMA
         AND rc.TABLE_NAME = s.TABLE_NAME
         AND rc.CONSTRAINT_NAME = s.INDEX_NAME
        WHERE s.TABLE_SCHEMA = '${SCHEMA}'
          AND LEFT(s.INDEX_NAME, 4) <> 'idx_'
          AND tc.CONSTRAINT_NAME IS NULL
          AND rc.CONSTRAINT_NAME IS NULL
      ) unexpected;
    "
  )"
  assert_zero "${unexpected_indexes}" \
    'no ordinary indexes outside the ten idx_* indexes and MySQL foreign-key support indexes'
}

assert_foreign_keys() {
  local expected
  local actual

  expected="$(
    cat <<'EXPECTED'
sys_permission|fk_sys_permission_created_by|created_by|sys_user|id|RESTRICT|RESTRICT
sys_permission|fk_sys_permission_updated_by|updated_by|sys_user|id|RESTRICT|RESTRICT
sys_role|fk_sys_role_created_by|created_by|sys_user|id|RESTRICT|RESTRICT
sys_role|fk_sys_role_updated_by|updated_by|sys_user|id|RESTRICT|RESTRICT
sys_role_assignment|fk_sys_role_assignment_approved|approved_by|sys_user|id|RESTRICT|RESTRICT
sys_role_assignment|fk_sys_role_assignment_created|created_by|sys_user|id|RESTRICT|RESTRICT
sys_role_assignment|fk_sys_role_assignment_executed|executed_by|sys_user|id|RESTRICT|RESTRICT
sys_role_assignment|fk_sys_role_assignment_requested|requested_by|sys_user|id|RESTRICT|RESTRICT
sys_role_assignment|fk_sys_role_assignment_reviewed|reviewed_by|sys_user|id|RESTRICT|RESTRICT
sys_role_assignment|fk_sys_role_assignment_role|role_id|sys_role|id|RESTRICT|RESTRICT
sys_role_assignment|fk_sys_role_assignment_target|target_user_id|sys_user|id|RESTRICT|RESTRICT
sys_role_assignment|fk_sys_role_assignment_updated|updated_by|sys_user|id|RESTRICT|RESTRICT
sys_role_permission|fk_sys_role_permission_permission|permission_id|sys_permission|id|RESTRICT|RESTRICT
sys_role_permission|fk_sys_role_permission_role|role_id|sys_role|id|RESTRICT|RESTRICT
sys_user|fk_sys_user_created_by|created_by|sys_user|id|RESTRICT|RESTRICT
sys_user|fk_sys_user_updated_by|updated_by|sys_user|id|RESTRICT|RESTRICT
sys_user_role|fk_sys_user_role_assignment|source_assignment_id|sys_role_assignment|id|RESTRICT|RESTRICT
sys_user_role|fk_sys_user_role_created_by|created_by|sys_user|id|RESTRICT|RESTRICT
sys_user_role|fk_sys_user_role_role|role_id|sys_role|id|RESTRICT|RESTRICT
sys_user_role|fk_sys_user_role_updated_by|updated_by|sys_user|id|RESTRICT|RESTRICT
sys_user_role|fk_sys_user_role_user|user_id|sys_user|id|RESTRICT|RESTRICT
EXPECTED
  )"
  actual="$(
    query_server "
      SELECT CONCAT(
        kcu.TABLE_NAME,
        '|',
        kcu.CONSTRAINT_NAME,
        '|',
        GROUP_CONCAT(kcu.COLUMN_NAME ORDER BY kcu.ORDINAL_POSITION SEPARATOR ','),
        '|',
        kcu.REFERENCED_TABLE_NAME,
        '|',
        GROUP_CONCAT(
          kcu.REFERENCED_COLUMN_NAME
          ORDER BY kcu.ORDINAL_POSITION
          SEPARATOR ','
        ),
        '|',
        rc.UPDATE_RULE,
        '|',
        rc.DELETE_RULE
      )
      FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE kcu
      JOIN INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS rc
        ON rc.CONSTRAINT_SCHEMA = kcu.CONSTRAINT_SCHEMA
       AND rc.TABLE_NAME = kcu.TABLE_NAME
       AND rc.CONSTRAINT_NAME = kcu.CONSTRAINT_NAME
      WHERE kcu.CONSTRAINT_SCHEMA = '${SCHEMA}'
        AND kcu.REFERENCED_TABLE_NAME IS NOT NULL
      GROUP BY
        kcu.TABLE_NAME,
        kcu.CONSTRAINT_NAME,
        kcu.REFERENCED_TABLE_NAME,
        rc.UPDATE_RULE,
        rc.DELETE_RULE
      ORDER BY kcu.TABLE_NAME, kcu.CONSTRAINT_NAME;
    "
  )"
  assert_eq "${expected}" "${actual}" \
    'exact 21 named foreign keys, columns, references, and RESTRICT rules'
}

assert_show_create_constraints() {
  local table
  local constraint_name
  local show_create

  while IFS='|' read -r table constraint_name; do
    show_create="$(query_db "SHOW CREATE TABLE \`${table}\`;")"
    if ! grep -Fq -- "\`${constraint_name}\`" <<< "${show_create}"; then
      die "SHOW CREATE TABLE ${table} is missing ${constraint_name}"
    fi
    if grep -Eq -- '`pk_sys_' <<< "${show_create}"; then
      die "SHOW CREATE TABLE ${table} must not contain a pk_sys_* physical name"
    fi
  done <<'CONSTRAINTS'
sys_user|uk_sys_user_username
sys_user|ck_sys_user_status
sys_user|ck_sys_user_username_nonblank
sys_user|ck_sys_user_display_name_nonblank
sys_user|ck_sys_user_password_hash_nonblank
sys_role|uk_sys_role_code
sys_role|uk_sys_role_name
sys_role|ck_sys_role_risk_level
sys_role|ck_sys_role_status
sys_role|ck_sys_role_is_builtin
sys_permission|uk_sys_permission_code
sys_permission|ck_sys_permission_module
sys_permission|ck_sys_permission_execution_mode
sys_permission|ck_sys_permission_is_builtin
sys_role_assignment|uk_sys_role_assignment_no
sys_role_assignment|ck_sys_role_assignment_type
sys_role_assignment|ck_sys_role_assignment_approval
sys_role_assignment|ck_sys_role_assignment_status
sys_role_assignment|ck_sys_role_assignment_valid_period
sys_role_assignment|ck_sys_role_assignment_creator
sys_role_assignment|ck_sys_role_assignment_review_pair
sys_role_assignment|ck_sys_role_assignment_approve_pair
sys_role_assignment|ck_sys_role_assignment_execute_pair
sys_role_assignment|ck_sys_role_assignment_review_sod
sys_role_assignment|ck_sys_role_assignment_approve_sod
sys_role_assignment|ck_sys_role_assignment_review_approve_sod
sys_role_assignment|ck_sys_role_assignment_execute_sod
sys_user_role|uk_sys_user_role
sys_user_role|uk_sys_user_role_source_assignment
sys_user_role|ck_sys_user_role_status
sys_user_role|ck_sys_user_role_valid_period
sys_role_permission|uk_sys_role_permission
CONSTRAINTS
}

assert_baseline_counts() {
  local expected
  local actual

  expected="$(
    cat <<'EXPECTED'
sys_permission|160
sys_role|10
sys_role_assignment|0
sys_role_permission|233
sys_user|0
sys_user_role|0
EXPECTED
  )"
  actual="$(
    query_db "
      SELECT 'sys_permission', COUNT(*) FROM sys_permission
      UNION ALL
      SELECT 'sys_role', COUNT(*) FROM sys_role
      UNION ALL
      SELECT 'sys_role_assignment', COUNT(*) FROM sys_role_assignment
      UNION ALL
      SELECT 'sys_role_permission', COUNT(*) FROM sys_role_permission
      UNION ALL
      SELECT 'sys_user', COUNT(*) FROM sys_user
      UNION ALL
      SELECT 'sys_user_role', COUNT(*) FROM sys_user_role
      ORDER BY 1;
    " | awk -F '\t' '{ print $1 "|" $2 }'
  )"
  assert_eq "${expected}" "${actual}" 'baseline row counts'
}

assert_role_seeds() {
  local actual
  local actual_hash
  local expected
  # Independent canonical SHA-256 of the ten complete Section 11 role rows.
  local expected_hash='ec4c6c4fd83950b0ad50dc1508961105e7460151e0d60d233de05f285fd7cf85'

  actual="$(
    query_db "
      SELECT CONCAT_WS(
        CHAR(9),
        role_code,
        role_name,
        risk_level,
        COALESCE(description, '<NULL>'),
        status,
        is_builtin
      )
      FROM sys_role
      ORDER BY role_code;
    "
  )"
  actual_hash="$(sha256_text "${actual}")"
  assert_eq "${expected_hash}" "${actual_hash}" \
    'complete ten-role seed manifest'

  expected="$(
    cat <<'EXPECTED'
ACCEPTANCE_INSPECTOR
AUDIT_VIEWER
OUTBOUND_REVIEWER
QUALITY_HEAD
QUALITY_MANAGER
SYSTEM_ADMIN
EXPECTED
  )"
  actual="$(
    query_db "
      SELECT role_code
      FROM sys_role
      WHERE risk_level = 'HIGH'
      ORDER BY role_code;
    "
  )"
  assert_eq "${expected}" "${actual}" 'exact high-risk role set'
}

assert_permission_seeds() {
  local actual
  local actual_hash
  local expected
  local duplicate_count
  # Independent canonical SHA-256 of Appendix A's 160
  # permission_code/module_code/permission_name/execution_mode rows.
  local expected_hash='b52d3d4f012fa10cb454eb2414fbaee0ed77196189860ceeafd42c8bfde78fca'

  duplicate_count="$(
    query_db "
      SELECT COUNT(*)
      FROM (
        SELECT permission_code
        FROM sys_permission
        GROUP BY permission_code
        HAVING COUNT(*) > 1
      ) duplicate_codes;
    "
  )"
  assert_zero "${duplicate_count}" 'permission_code duplicates'

  actual="$(
    query_db "
      SELECT CONCAT_WS(
        CHAR(9),
        permission_code,
        module_code,
        permission_name,
        execution_mode
      )
      FROM sys_permission
      ORDER BY permission_code;
    "
  )"
  actual_hash="$(sha256_text "${actual}")"
  assert_eq "${expected_hash}" "${actual_hash}" \
    'complete 160-permission Appendix A manifest'

  expected="$(
    cat <<'EXPECTED'
ACPT|10
BAK|10
DEMO|5
GD|17
INV|12
MD|11
OUT|12
PO|9
QA|16
QE|13
RC|9
SO|14
SYS|16
TRACE|6
EXPECTED
  )"
  actual="$(
    query_db "
      SELECT CONCAT(module_code, '|', COUNT(*))
      FROM sys_permission
      GROUP BY module_code
      ORDER BY module_code;
    "
  )"
  assert_eq "${expected}" "${actual}" 'permission module counts'

  expected="$(
    cat <<'EXPECTED'
NOT_OPEN|4
PROHIBITED|22
ROLE|110
ROLE_AND_SYSTEM|17
SYSTEM|7
EXPECTED
  )"
  actual="$(
    query_db "
      SELECT CONCAT(execution_mode, '|', COUNT(*))
      FROM sys_permission
      GROUP BY execution_mode
      ORDER BY execution_mode;
    "
  )"
  assert_eq "${expected}" "${actual}" 'permission execution_mode counts'
}

assert_role_permission_seeds() {
  local actual
  local actual_hash
  local expected
  local duplicate_count
  local invalid_count
  local missing_count
  # Independent canonical SHA-256 of Appendix A's 233 sorted
  # role_code/permission_code pairs. Counts alone are not the oracle.
  local expected_hash='5d1957cdb5d760e0c0c75dbd4a9918b560217ada430aa266424f1584e2cd96a4'

  duplicate_count="$(
    query_db "
      SELECT COUNT(*)
      FROM (
        SELECT role_id, permission_id
        FROM sys_role_permission
        GROUP BY role_id, permission_id
        HAVING COUNT(*) > 1
      ) duplicate_pairs;
    "
  )"
  assert_zero "${duplicate_count}" 'role-permission duplicate pairs'

  actual="$(
    query_db "
      SELECT CONCAT_WS(CHAR(9), r.role_code, p.permission_code)
      FROM sys_role_permission rp
      JOIN sys_role r ON r.id = rp.role_id
      JOIN sys_permission p ON p.id = rp.permission_id
      ORDER BY r.role_code, p.permission_code;
    "
  )"
  actual_hash="$(sha256_text "${actual}")"
  assert_eq "${expected_hash}" "${actual_hash}" \
    'complete 233-pair Appendix A role-permission manifest'

  expected="$(
    cat <<'EXPECTED'
ACCEPTANCE_INSPECTOR|14
AUDIT_VIEWER|20
OUTBOUND_REVIEWER|8
PURCHASER|21
QUALITY_HEAD|29
QUALITY_MANAGER|53
RECEIVER|12
SALES_OPERATOR|24
SYSTEM_ADMIN|27
WAREHOUSE_OPERATOR|25
EXPECTED
  )"
  actual="$(
    query_db "
      SELECT CONCAT(r.role_code, '|', COUNT(*))
      FROM sys_role_permission rp
      JOIN sys_role r ON r.id = rp.role_id
      GROUP BY r.role_code
      ORDER BY r.role_code;
    "
  )"
  assert_eq "${expected}" "${actual}" 'per-role relationship counts'

  invalid_count="$(
    query_db "
      SELECT COUNT(*)
      FROM sys_role_permission rp
      JOIN sys_permission p ON p.id = rp.permission_id
      WHERE p.execution_mode IN ('SYSTEM', 'PROHIBITED', 'NOT_OPEN');
    "
  )"
  assert_zero "${invalid_count}" \
    'SYSTEM, PROHIBITED, and NOT_OPEN permissions must have no role relationships'

  missing_count="$(
    query_db "
      SELECT COUNT(*)
      FROM sys_permission p
      WHERE p.execution_mode IN ('ROLE', 'ROLE_AND_SYSTEM')
        AND NOT EXISTS (
          SELECT 1
          FROM sys_role_permission rp
          WHERE rp.permission_id = p.id
        );
    "
  )"
  assert_zero "${missing_count}" \
    'ROLE and ROLE_AND_SYSTEM permissions must have a relationship'

  invalid_count="$(
    query_db "
      SELECT COUNT(*)
      FROM sys_role_permission
      WHERE source_matrix_version <> 'v1.1';
    "
  )"
  assert_zero "${invalid_count}" \
    'all role-permission rows must use source_matrix_version v1.1'

  expected="$(
    cat <<'EXPECTED'
AUDIT_VIEWER
PURCHASER
QUALITY_HEAD
QUALITY_MANAGER
SALES_OPERATOR
EXPECTED
  )"
  actual="$(
    query_db "
      SELECT r.role_code
      FROM sys_role_permission rp
      JOIN sys_role r ON r.id = rp.role_id
      JOIN sys_permission p ON p.id = rp.permission_id
      WHERE p.permission_code = 'QA-016'
      ORDER BY r.role_code;
    "
  )"
  assert_eq "${expected}" "${actual}" 'QA-016 exact relationship set'

  invalid_count="$(
    query_db "
      SELECT COUNT(*)
      FROM sys_role_permission rp
      JOIN sys_permission p ON p.id = rp.permission_id
      WHERE p.permission_code IN ('PO-007', 'RC-008', 'SO-012');
    "
  )"
  assert_zero "${invalid_count}" \
    'PO-007, RC-008, and SO-012 must have no role relationships'

  expected="$(
    cat <<'EXPECTED'
SALES_OPERATOR
WAREHOUSE_OPERATOR
EXPECTED
  )"
  actual="$(
    query_db "
      SELECT r.role_code
      FROM sys_role_permission rp
      JOIN sys_role r ON r.id = rp.role_id
      JOIN sys_permission p ON p.id = rp.permission_id
      WHERE p.permission_code = 'SO-009'
      ORDER BY r.role_code;
    "
  )"
  assert_eq "${expected}" "${actual}" 'SO-009 action-family relationships'

  expected="$(
    cat <<'EXPECTED'
QUALITY_HEAD
QUALITY_MANAGER
WAREHOUSE_OPERATOR
EXPECTED
  )"
  actual="$(
    query_db "
      SELECT r.role_code
      FROM sys_role_permission rp
      JOIN sys_role r ON r.id = rp.role_id
      JOIN sys_permission p ON p.id = rp.permission_id
      WHERE p.permission_code = 'OUT-010'
      ORDER BY r.role_code;
    "
  )"
  assert_eq "${expected}" "${actual}" 'OUT-010 action-family relationships'
}

create_negative_test_support_data() {
  mysql_db --execute "
    INSERT INTO sys_user (
      username,
      display_name,
      password_hash,
      status
    ) VALUES
      (
        '${TEST_PREFIX}TARGET',
        '${TEST_PREFIX}目标用户',
        '${TEST_PREFIX}NONSECRET_HASH_VALUE',
        'DISABLED'
      ),
      (
        '${TEST_PREFIX}REQUESTER',
        '${TEST_PREFIX}申请人',
        '${TEST_PREFIX}NONSECRET_HASH_VALUE',
        'DISABLED'
      ),
      (
        '${TEST_PREFIX}REVIEWER',
        '${TEST_PREFIX}审核人',
        '${TEST_PREFIX}NONSECRET_HASH_VALUE',
        'DISABLED'
      ),
      (
        '${TEST_PREFIX}APPROVER',
        '${TEST_PREFIX}批准人',
        '${TEST_PREFIX}NONSECRET_HASH_VALUE',
        'DISABLED'
      ),
      (
        '${TEST_PREFIX}EXECUTOR',
        '${TEST_PREFIX}执行人',
        '${TEST_PREFIX}NONSECRET_HASH_VALUE',
        'DISABLED'
      );
  "

  assert_eq '5' "$(
    query_db "
      SELECT COUNT(*)
      FROM sys_user
      WHERE LEFT(username, CHAR_LENGTH('${TEST_PREFIX}')) = '${TEST_PREFIX}';
    "
  )" 'negative-test support user count'
}

assignment_insert_sql() {
  local assignment_no="$1"
  local assignment_type="$2"
  local status="$3"
  local reviewed_by="$4"
  local reviewed_at="$5"
  local approved_by="$6"
  local approved_at="$7"
  local executed_by="$8"
  local executed_at="$9"
  local target_id
  local requester_id
  local reviewer_id
  local approver_id
  local executor_id
  local role_id

  target_id="(SELECT id FROM sys_user WHERE username = '${TEST_PREFIX}TARGET')"
  requester_id="(SELECT id FROM sys_user WHERE username = '${TEST_PREFIX}REQUESTER')"
  reviewer_id="(SELECT id FROM sys_user WHERE username = '${TEST_PREFIX}REVIEWER')"
  approver_id="(SELECT id FROM sys_user WHERE username = '${TEST_PREFIX}APPROVER')"
  executor_id="(SELECT id FROM sys_user WHERE username = '${TEST_PREFIX}EXECUTOR')"
  role_id="(SELECT id FROM sys_role WHERE role_code = 'SYSTEM_ADMIN')"

  reviewed_by="${reviewed_by//REVIEWER_ID/${reviewer_id}}"
  reviewed_by="${reviewed_by//REQUESTER_ID/${requester_id}}"
  approved_by="${approved_by//APPROVER_ID/${approver_id}}"
  approved_by="${approved_by//REVIEWER_ID/${reviewer_id}}"
  approved_by="${approved_by//TARGET_ID/${target_id}}"
  executed_by="${executed_by//APPROVER_ID/${approver_id}}"
  executed_by="${executed_by//EXECUTOR_ID/${executor_id}}"

  printf '%s' "
    INSERT INTO sys_role_assignment (
      assignment_no,
      target_user_id,
      role_id,
      assignment_type,
      approval_required,
      status,
      requested_by,
      reviewed_by,
      reviewed_at,
      approved_by,
      approved_at,
      executed_by,
      executed_at,
      reason,
      created_by
    ) VALUES (
      '${assignment_no}',
      ${target_id},
      ${role_id},
      '${assignment_type}',
      0,
      '${status}',
      ${requester_id},
      ${reviewed_by},
      ${reviewed_at},
      ${approved_by},
      ${approved_at},
      ${executed_by},
      ${executed_at},
      '${TEST_PREFIX}角色分配约束测试',
      ${requester_id}
    );
  "
}

run_negative_tests() {
  local sql
  local assignment_invariant

  expect_mysql_failure \
    'duplicate username' \
    'ERROR 1062' \
    "INSERT INTO sys_user (username, display_name, password_hash)
       VALUES (
         '${TEST_PREFIX}TARGET',
         '${TEST_PREFIX}重复用户名',
         '${TEST_PREFIX}NONSECRET_HASH_VALUE'
       );" \
    "SELECT COUNT(*) FROM sys_user WHERE username = '${TEST_PREFIX}TARGET';" \
    '1'

  expect_mysql_failure \
    'illegal sys_user.status' \
    'ERROR 3819' \
    "INSERT INTO sys_user (username, display_name, password_hash, status)
       VALUES (
         '${TEST_PREFIX}BAD_USER_STATUS',
         '${TEST_PREFIX}非法用户状态',
         '${TEST_PREFIX}NONSECRET_HASH_VALUE',
         'INVALID'
       );" \
    "SELECT COUNT(*) FROM sys_user WHERE username = '${TEST_PREFIX}BAD_USER_STATUS';" \
    '0'

  expect_mysql_failure \
    'blank password_hash' \
    'ERROR 3819' \
    "INSERT INTO sys_user (username, display_name, password_hash)
       VALUES (
         '${TEST_PREFIX}BLANK_HASH',
         '${TEST_PREFIX}空白哈希',
         '   '
       );" \
    "SELECT COUNT(*) FROM sys_user WHERE username = '${TEST_PREFIX}BLANK_HASH';" \
    '0'

  expect_mysql_failure \
    'duplicate role_code' \
    'ERROR 1062' \
    "INSERT INTO sys_role (role_code, role_name, risk_level, description)
       VALUES (
         'SYSTEM_ADMIN',
         '${TEST_PREFIX}重复角色代码',
         'NORMAL',
         '${TEST_PREFIX}重复角色代码测试'
       );" \
    "SELECT COUNT(*) FROM sys_role WHERE role_code = 'SYSTEM_ADMIN';" \
    '1'

  expect_mysql_failure \
    'illegal risk_level' \
    'ERROR 3819' \
    "INSERT INTO sys_role (role_code, role_name, risk_level, description)
       VALUES (
         '${TEST_PREFIX}BAD_RISK',
         '${TEST_PREFIX}非法风险级别',
         'INVALID',
         '${TEST_PREFIX}非法风险级别测试'
       );" \
    "SELECT COUNT(*) FROM sys_role WHERE role_code = '${TEST_PREFIX}BAD_RISK';" \
    '0'

  expect_mysql_failure \
    'duplicate permission_code' \
    'ERROR 1062' \
    "INSERT INTO sys_permission (
       permission_code, permission_name, module_code, execution_mode
     ) VALUES (
       'SYS-001', '${TEST_PREFIX}重复权限编号', 'SYS', 'ROLE'
     );" \
    "SELECT COUNT(*) FROM sys_permission WHERE permission_code = 'SYS-001';" \
    '1'

  expect_mysql_failure \
    'illegal execution_mode' \
    'ERROR 3819' \
    "INSERT INTO sys_permission (
       permission_code, permission_name, module_code, execution_mode
     ) VALUES (
       '${TEST_PREFIX}BAD_MODE',
       '${TEST_PREFIX}非法执行模式',
       'SYS',
       'INVALID'
     );" \
    "SELECT COUNT(*) FROM sys_permission
       WHERE permission_code = '${TEST_PREFIX}BAD_MODE';" \
    '0'

  assert_eq '0' "$(
    query_db 'SELECT COUNT(*) FROM sys_user WHERE id = 9223372036854775807;'
  )" 'reserved nonexistent user id must be absent'

  expect_mysql_failure \
    'nonexistent user_id in sys_user_role' \
    'ERROR 1452' \
    "INSERT INTO sys_user_role (user_id, role_id)
       SELECT 9223372036854775807, id
       FROM sys_role
       WHERE role_code = 'PURCHASER';" \
    'SELECT COUNT(*) FROM sys_user_role WHERE user_id = 9223372036854775807;' \
    '0'

  mysql_db --execute "
    INSERT INTO sys_user_role (user_id, role_id)
    SELECT u.id, r.id
    FROM sys_user u
    JOIN sys_role r ON r.role_code = 'PURCHASER'
    WHERE u.username = '${TEST_PREFIX}TARGET';
  "

  expect_mysql_failure \
    'duplicate user-role pair' \
    'ERROR 1062' \
    "INSERT INTO sys_user_role (user_id, role_id)
       SELECT u.id, r.id
       FROM sys_user u
       JOIN sys_role r ON r.role_code = 'PURCHASER'
       WHERE u.username = '${TEST_PREFIX}TARGET';" \
    "SELECT COUNT(*)
       FROM sys_user_role ur
       JOIN sys_user u ON u.id = ur.user_id
       JOIN sys_role r ON r.id = ur.role_id
       WHERE u.username = '${TEST_PREFIX}TARGET'
         AND r.role_code = 'PURCHASER';" \
    '1'

  expect_mysql_failure \
    'invalid user-role validity period' \
    'ERROR 3819' \
    "INSERT INTO sys_user_role (
       user_id, role_id, valid_from, valid_to
     )
     SELECT
       u.id,
       r.id,
       '2030-01-02 00:00:00.000',
       '2030-01-01 00:00:00.000'
     FROM sys_user u
     JOIN sys_role r ON r.role_code = 'RECEIVER'
     WHERE u.username = '${TEST_PREFIX}TARGET';" \
    "SELECT COUNT(*)
       FROM sys_user_role ur
       JOIN sys_user u ON u.id = ur.user_id
       JOIN sys_role r ON r.id = ur.role_id
       WHERE u.username = '${TEST_PREFIX}TARGET'
         AND r.role_code = 'RECEIVER';" \
    '0'

  expect_mysql_failure \
    'duplicate role-permission pair' \
    'ERROR 1062' \
    "INSERT INTO sys_role_permission (
       role_id, permission_id, source_matrix_version
     )
     SELECT r.id, p.id, 'v1.1'
     FROM sys_role r
     JOIN sys_permission p ON p.permission_code = 'SYS-001'
     WHERE r.role_code = 'SYSTEM_ADMIN';" \
    "SELECT COUNT(*)
       FROM sys_role_permission rp
       JOIN sys_role r ON r.id = rp.role_id
       JOIN sys_permission p ON p.id = rp.permission_id
       WHERE r.role_code = 'SYSTEM_ADMIN'
         AND p.permission_code = 'SYS-001';" \
    '1'

  assignment_invariant="SELECT COUNT(*) FROM sys_role_assignment
    WHERE assignment_no = '%s';"

  sql="$(assignment_insert_sql \
    "${TEST_PREFIX}BAD_TYPE" \
    'INVALID' \
    'PENDING_REVIEW' \
    'NULL' \
    'NULL' \
    'NULL' \
    'NULL' \
    'NULL' \
    'NULL')"
  expect_mysql_failure \
    'illegal assignment_type' \
    'ERROR 3819' \
    "${sql}" \
    "$(printf "${assignment_invariant}" "${TEST_PREFIX}BAD_TYPE")" \
    '0'

  sql="$(assignment_insert_sql \
    "${TEST_PREFIX}BAD_STATUS" \
    'GRANT' \
    'INVALID' \
    'NULL' \
    'NULL' \
    'NULL' \
    'NULL' \
    'NULL' \
    'NULL')"
  expect_mysql_failure \
    'illegal assignment status' \
    'ERROR 3819' \
    "${sql}" \
    "$(printf "${assignment_invariant}" "${TEST_PREFIX}BAD_STATUS")" \
    '0'

  sql="$(assignment_insert_sql \
    "${TEST_PREFIX}REVIEW_REQUESTER" \
    'GRANT' \
    'PENDING_REVIEW' \
    'REQUESTER_ID' \
    "'2026-07-30 00:00:00.000'" \
    'NULL' \
    'NULL' \
    'NULL' \
    'NULL')"
  expect_mysql_failure \
    'reviewer equals requester' \
    'ERROR 3819' \
    "${sql}" \
    "$(printf "${assignment_invariant}" "${TEST_PREFIX}REVIEW_REQUESTER")" \
    '0'

  sql="$(assignment_insert_sql \
    "${TEST_PREFIX}APPROVE_TARGET" \
    'GRANT' \
    'PENDING_APPROVAL' \
    'NULL' \
    'NULL' \
    'TARGET_ID' \
    "'2026-07-30 00:00:00.000'" \
    'NULL' \
    'NULL')"
  expect_mysql_failure \
    'approver equals target user' \
    'ERROR 3819' \
    "${sql}" \
    "$(printf "${assignment_invariant}" "${TEST_PREFIX}APPROVE_TARGET")" \
    '0'

  sql="$(assignment_insert_sql \
    "${TEST_PREFIX}REVIEW_APPROVE" \
    'GRANT' \
    'PENDING_APPROVAL' \
    'REVIEWER_ID' \
    "'2026-07-30 00:00:00.000'" \
    'REVIEWER_ID' \
    "'2026-07-30 00:01:00.000'" \
    'NULL' \
    'NULL')"
  expect_mysql_failure \
    'reviewer equals approver' \
    'ERROR 3819' \
    "${sql}" \
    "$(printf "${assignment_invariant}" "${TEST_PREFIX}REVIEW_APPROVE")" \
    '0'

  sql="$(assignment_insert_sql \
    "${TEST_PREFIX}APPROVE_EXECUTE" \
    'GRANT' \
    'PENDING_EXECUTION' \
    'NULL' \
    'NULL' \
    'APPROVER_ID' \
    "'2026-07-30 00:00:00.000'" \
    'APPROVER_ID' \
    "'2026-07-30 00:01:00.000'")"
  expect_mysql_failure \
    'approver equals executor' \
    'ERROR 3819' \
    "${sql}" \
    "$(printf "${assignment_invariant}" "${TEST_PREFIX}APPROVE_EXECUTE")" \
    '0'

  sql="$(assignment_insert_sql \
    "${TEST_PREFIX}REVIEW_PAIR" \
    'GRANT' \
    'PENDING_REVIEW' \
    'REVIEWER_ID' \
    'NULL' \
    'NULL' \
    'NULL' \
    'NULL' \
    'NULL')"
  expect_mysql_failure \
    'reviewed_by and reviewed_at must be paired' \
    'ERROR 3819' \
    "${sql}" \
    "$(printf "${assignment_invariant}" "${TEST_PREFIX}REVIEW_PAIR")" \
    '0'

  sql="$(assignment_insert_sql \
    "${TEST_PREFIX}APPROVE_PAIR" \
    'GRANT' \
    'PENDING_APPROVAL' \
    'NULL' \
    'NULL' \
    'APPROVER_ID' \
    'NULL' \
    'NULL' \
    'NULL')"
  expect_mysql_failure \
    'approved_by and approved_at must be paired' \
    'ERROR 3819' \
    "${sql}" \
    "$(printf "${assignment_invariant}" "${TEST_PREFIX}APPROVE_PAIR")" \
    '0'

  sql="$(assignment_insert_sql \
    "${TEST_PREFIX}EXECUTE_PAIR" \
    'GRANT' \
    'PENDING_EXECUTION' \
    'NULL' \
    'NULL' \
    'NULL' \
    'NULL' \
    'EXECUTOR_ID' \
    'NULL')"
  expect_mysql_failure \
    'executed_by and executed_at must be paired' \
    'ERROR 3819' \
    "${sql}" \
    "$(printf "${assignment_invariant}" "${TEST_PREFIX}EXECUTE_PAIR")" \
    '0'
}

cleanup_negative_test_support_data() {
  mysql_db --execute "
    DELETE ur
    FROM sys_user_role ur
    JOIN sys_user u ON u.id = ur.user_id
    WHERE LEFT(u.username, CHAR_LENGTH('${TEST_PREFIX}')) = '${TEST_PREFIX}';

    DELETE rp
    FROM sys_role_permission rp
    LEFT JOIN sys_role r ON r.id = rp.role_id
    LEFT JOIN sys_permission p ON p.id = rp.permission_id
    WHERE LEFT(COALESCE(r.role_code, ''), CHAR_LENGTH('${TEST_PREFIX}')) = '${TEST_PREFIX}'
       OR LEFT(COALESCE(p.permission_code, ''), CHAR_LENGTH('${TEST_PREFIX}')) = '${TEST_PREFIX}';

    DELETE FROM sys_role_assignment
    WHERE LEFT(assignment_no, CHAR_LENGTH('${TEST_PREFIX}')) = '${TEST_PREFIX}';

    DELETE FROM sys_permission
    WHERE LEFT(permission_code, CHAR_LENGTH('${TEST_PREFIX}')) = '${TEST_PREFIX}';

    DELETE FROM sys_role
    WHERE LEFT(role_code, CHAR_LENGTH('${TEST_PREFIX}')) = '${TEST_PREFIX}';

    DELETE FROM sys_user
    WHERE LEFT(username, CHAR_LENGTH('${TEST_PREFIX}')) = '${TEST_PREFIX}';
  "
}

assert_test_support_removed() {
  local actual

  actual="$(
    query_db "
      SELECT
        (SELECT COUNT(*) FROM sys_user
          WHERE LEFT(username, CHAR_LENGTH('${TEST_PREFIX}')) = '${TEST_PREFIX}')
        +
        (SELECT COUNT(*) FROM sys_role
          WHERE LEFT(role_code, CHAR_LENGTH('${TEST_PREFIX}')) = '${TEST_PREFIX}')
        +
        (SELECT COUNT(*) FROM sys_permission
          WHERE LEFT(permission_code, CHAR_LENGTH('${TEST_PREFIX}')) = '${TEST_PREFIX}')
        +
        (SELECT COUNT(*) FROM sys_role_assignment
          WHERE LEFT(assignment_no, CHAR_LENGTH('${TEST_PREFIX}')) = '${TEST_PREFIX}');
    "
  )"
  assert_zero "${actual}" 'negative-test support rows after cleanup'
}

assert_sensitive_data_boundaries() {
  local actual

  actual="$(
    query_server "
      SELECT CONCAT(TABLE_NAME, '.', COLUMN_NAME)
      FROM INFORMATION_SCHEMA.COLUMNS
      WHERE TABLE_SCHEMA = '${SCHEMA}'
        AND LOWER(COLUMN_NAME) LIKE '%password%'
      ORDER BY TABLE_NAME, COLUMN_NAME;
    "
  )"
  assert_eq 'sys_user.password_hash' "${actual}" \
    'password_hash must be the only password-related database column'

  assert_static_sql_boundaries
}

run_backend_regression() {
  mvn -f "${POM_FILE}" -DskipTests compile

  SPRING_DATASOURCE_URL='jdbc:mysql://127.0.0.1:1/__db_base_01_no_connect?connectTimeout=1000&socketTimeout=1000&useSSL=false&allowPublicKeyRetrieval=false' \
  SPRING_DATASOURCE_USERNAME='__DB_BASE_01_NO_CONNECT__' \
  SPRING_DATASOURCE_PASSWORD='' \
  SPRING_DATASOURCE_HIKARI_CONNECTIONTIMEOUT='1000' \
  SPRING_DATASOURCE_HIKARI_INITIALIZATIONFAILTIMEOUT='-1' \
  SPRING_DATASOURCE_HIKARI_MINIMUMIDLE='0' \
  SPRING_SQL_INIT_MODE='never' \
    mvn -f "${POM_FILE}" test
}

drop_schema_after_success() {
  local remaining

  assert_drop_guard
  query_server "DROP DATABASE \`${SCHEMA}\`;" > /dev/null
  schema_created=0

  remaining="$(
    query_server "
      SELECT COUNT(*)
      FROM INFORMATION_SCHEMA.SCHEMATA
      WHERE SCHEMA_NAME = '${SCHEMA}';
    "
  )"
  if [[ "${remaining}" != '0' ]]; then
    schema_created=1
    die 'test Schema still exists after the guarded success cleanup'
  fi
}

main() {
  assert_static_sql_boundaries
  assert_server_prerequisites
  rebuild_empty_schema
  assert_db_session

  mysql_db < "${DDL_FILE}"
  assert_db_session
  mysql_db < "${SEED_FILE}"
  assert_db_session

  assert_schema_and_tables
  assert_column_definitions
  assert_primary_keys
  assert_unique_constraints
  assert_check_constraints
  assert_explicit_indexes
  assert_foreign_keys
  assert_show_create_constraints

  assert_baseline_counts
  assert_role_seeds
  assert_permission_seeds
  assert_role_permission_seeds
  assert_sensitive_data_boundaries

  create_negative_test_support_data
  run_negative_tests
  cleanup_negative_test_support_data
  assert_test_support_removed

  assert_baseline_counts
  assert_role_seeds
  assert_permission_seeds
  assert_role_permission_seeds
  assert_db_session
  assert_sensitive_data_boundaries

  run_backend_regression
  drop_schema_after_success
  printf 'DB-BASE-01 database verification passed; removed test Schema: %s\n' \
    "${SCHEMA}"
}

main "$@"

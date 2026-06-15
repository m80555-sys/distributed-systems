-- Testra Count target validation for atl_clin_cdso.rbqm_study_trendline.
-- Returns the target primary key row count for the current cycle.
-- Replace ${cycle_id} with the latest cycle id for the run, formatted as YYYY-MM-DD.

WITH target_pk AS (
    SELECT
        study_id,
        snapshot_date,
        interval_start_date
    FROM atl_clin_cdso.rbqm_study_trendline
    WHERE snapshot_date = TO_DATE('${cycle_id}', 'yyyy-MM-dd')
)
SELECT
    COUNT(*) AS target_pk_count
FROM target_pk;

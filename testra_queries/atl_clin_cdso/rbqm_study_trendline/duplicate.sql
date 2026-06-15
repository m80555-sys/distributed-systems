-- Testra Duplicate validation for atl_clin_cdso.rbqm_study_trendline.
-- Uses only the primary key: study_id, snapshot_date, interval_start_date.

SELECT
    study_id,
    snapshot_date,
    interval_start_date,
    COUNT(*) AS duplicate_count
FROM atl_clin_cdso.rbqm_study_trendline
GROUP BY
    study_id,
    snapshot_date,
    interval_start_date
HAVING COUNT(*) > 1;

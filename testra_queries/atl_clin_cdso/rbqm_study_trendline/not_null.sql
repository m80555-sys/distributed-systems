-- Testra Not Null validation for atl_clin_cdso.rbqm_study_trendline.
-- Includes the primary key plus created_date, modified_date, and _deleted_flag_.

SELECT
    study_id,
    snapshot_date,
    interval_start_date,
    dv_insrt_ts AS created_date,
    dv_updt_ts AS modified_date,
    dv_is_deleted AS _deleted_flag_
FROM atl_clin_cdso.rbqm_study_trendline
WHERE study_id IS NULL
    OR snapshot_date IS NULL
    OR interval_start_date IS NULL
    OR dv_insrt_ts IS NULL
    OR dv_updt_ts IS NULL
    OR dv_is_deleted IS NULL;

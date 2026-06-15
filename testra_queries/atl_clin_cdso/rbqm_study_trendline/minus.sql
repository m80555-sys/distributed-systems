-- Testra Minus validation for atl_clin_cdso.rbqm_study_trendline.
-- Replace ${cycle_id} with the latest cycle id for the run, formatted as YYYY-MM-DD.

SELECT
    study_id,
    TO_DATE('${cycle_id}', 'yyyy-MM-dd') AS snapshot_date,
    interval_start_date,
    interval_end_date,
    median_sites_with_red_kri,
    'N' AS dv_is_deleted
FROM (
    SELECT
        study_id,
        interval_start_date,
        interval_end_date,
        median_sites_with_red_kri,
        ROW_NUMBER() OVER (
            PARTITION BY study_id
            ORDER BY interval_bucket DESC
        ) AS bucket_rank
    FROM (
        SELECT
            study_id,
            interval_bucket,
            MIN(snapshot_date) AS interval_start_date,
            MAX(snapshot_date) AS interval_end_date,
            ROUND(MEDIAN(count_of_sites_with_red_kri), 2) AS median_sites_with_red_kri
        FROM (
            SELECT
                study_id,
                snapshot_date,
                count_of_sites_with_red_kri,
                FLOOR(
                    DATEDIFF(
                        snapshot_date,
                        MIN(snapshot_date) OVER (PARTITION BY study_id)
                    ) / 28
                ) AS interval_bucket
            FROM (
                SELECT
                    h.study_id,
                    CAST(h.snapshot_date AS DATE) AS snapshot_date,
                    COUNT(DISTINCT h.site_id) AS count_of_sites_with_red_kri
                FROM atl_clin_cdso.rbqm_stat_study_site_kri_output_history h
                INNER JOIN tl_clin_cdso.RBQM_MH_ALIAS_MASTER a
                    ON h.study_id = a.study_id
                WHERE LOWER(h.kri_level_indicator) = 'red'
                GROUP BY
                    h.study_id,
                    CAST(h.snapshot_date AS DATE)
            ) site_counts
        ) bucketed_counts
        GROUP BY
            study_id,
            interval_bucket
    ) interval_metrics
) source_expected
WHERE bucket_rank <= 5
MINUS
SELECT
    study_id,
    snapshot_date,
    interval_start_date,
    interval_end_date,
    median_sites_with_red_kri,
    dv_is_deleted
FROM atl_clin_cdso.rbqm_study_trendline
WHERE snapshot_date = TO_DATE('${cycle_id}', 'yyyy-MM-dd');

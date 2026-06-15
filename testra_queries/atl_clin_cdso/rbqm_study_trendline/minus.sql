-- Testra Minus validation for atl_clin_cdso.rbqm_study_trendline.
-- Replace ${cycle_id} with the latest cycle id for the run, formatted as YYYY-MM-DD.

WITH filtered_source AS (
    SELECT
        h.study_id,
        h.site_id,
        CAST(h.snapshot_date AS DATE) AS snapshot_date
    FROM atl_clin_cdso.rbqm_stat_study_site_kri_output_history h
    INNER JOIN tl_clin_cdso.RBQM_MH_ALIAS_MASTER a
        ON h.study_id = a.study_id
    WHERE LOWER(h.kri_level_indicator) = 'red'
),
site_counts AS (
    SELECT
        study_id,
        snapshot_date,
        COUNT(DISTINCT site_id) AS count_of_sites_with_red_kri
    FROM filtered_source
    GROUP BY
        study_id,
        snapshot_date
),
bucketed_counts AS (
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
    FROM site_counts
),
interval_metrics AS (
    SELECT
        study_id,
        interval_bucket,
        MIN(snapshot_date) AS interval_start_date,
        MAX(snapshot_date) AS interval_end_date,
        ROUND(MEDIAN(count_of_sites_with_red_kri), 2) AS median_sites_with_red_kri
    FROM bucketed_counts
    GROUP BY
        study_id,
        interval_bucket
),
ranked_intervals AS (
    SELECT
        study_id,
        interval_start_date,
        interval_end_date,
        median_sites_with_red_kri,
        ROW_NUMBER() OVER (
            PARTITION BY study_id
            ORDER BY interval_bucket DESC
        ) AS bucket_rank
    FROM interval_metrics
),
source_expected AS (
    SELECT
        study_id,
        TO_DATE('${cycle_id}', 'yyyy-MM-dd') AS snapshot_date,
        interval_start_date,
        interval_end_date,
        median_sites_with_red_kri,
        'N' AS dv_is_deleted
    FROM ranked_intervals
    WHERE bucket_rank <= 5
),
target_actual AS (
    SELECT
        study_id,
        snapshot_date,
        interval_start_date,
        interval_end_date,
        median_sites_with_red_kri,
        dv_is_deleted
    FROM atl_clin_cdso.rbqm_study_trendline
    WHERE snapshot_date = TO_DATE('${cycle_id}', 'yyyy-MM-dd')
)
SELECT
    study_id,
    snapshot_date,
    interval_start_date,
    interval_end_date,
    median_sites_with_red_kri,
    dv_is_deleted
FROM source_expected
MINUS
SELECT
    study_id,
    snapshot_date,
    interval_start_date,
    interval_end_date,
    median_sites_with_red_kri,
    dv_is_deleted
FROM target_actual;

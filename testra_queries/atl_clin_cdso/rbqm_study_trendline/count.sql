-- Testra Count validation for atl_clin_cdso.rbqm_study_trendline.
-- Compares source-derived and target primary key counts for the current cycle.
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
        FLOOR(
            DATEDIFF(
                snapshot_date,
                MIN(snapshot_date) OVER (PARTITION BY study_id)
            ) / 28
        ) AS interval_bucket
    FROM site_counts
),
intervals AS (
    SELECT
        study_id,
        interval_bucket,
        MIN(snapshot_date) AS interval_start_date
    FROM bucketed_counts
    GROUP BY
        study_id,
        interval_bucket
),
source_pk AS (
    SELECT
        study_id,
        TO_DATE('${cycle_id}', 'yyyy-MM-dd') AS snapshot_date,
        interval_start_date
    FROM (
        SELECT
            study_id,
            interval_start_date,
            ROW_NUMBER() OVER (
                PARTITION BY study_id
                ORDER BY interval_bucket DESC
            ) AS bucket_rank
        FROM intervals
    ) ranked_intervals
    WHERE bucket_rank <= 5
),
target_pk AS (
    SELECT
        study_id,
        snapshot_date,
        interval_start_date
    FROM atl_clin_cdso.rbqm_study_trendline
    WHERE snapshot_date = TO_DATE('${cycle_id}', 'yyyy-MM-dd')
),
source_count AS (
    SELECT COUNT(*) AS pk_count
    FROM source_pk
),
target_count AS (
    SELECT COUNT(*) AS pk_count
    FROM target_pk
)
SELECT
    source_count.pk_count AS source_pk_count,
    target_count.pk_count AS target_pk_count
FROM source_count
CROSS JOIN target_count
WHERE source_count.pk_count <> target_count.pk_count;

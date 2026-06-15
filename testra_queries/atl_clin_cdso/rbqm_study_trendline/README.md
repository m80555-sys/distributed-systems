# Testra queries for `atl_clin_cdso.rbqm_study_trendline`

This directory contains the requested Testra validation queries for the `rbqm_study_trendline` user story:

- `minus.sql` compares source-derived rows to target rows using the primary key plus the transformation columns from the user story.
- `duplicate.sql` checks duplicate rows using only the primary key: `study_id`, `snapshot_date`, `interval_start_date`.
- `not_null.sql` checks the primary key plus audit fields. The target audit fields from the user story are selected as Testra aliases: `dv_insrt_ts AS created_date`, `dv_updt_ts AS modified_date`, and `dv_is_deleted AS _deleted_flag_`.
- `count.sql` compares source-derived and target row counts using only primary key columns.

Replace `${cycle_id}` with the latest cycle id for the run, formatted as `YYYY-MM-DD`, before executing the Minus and Count queries.

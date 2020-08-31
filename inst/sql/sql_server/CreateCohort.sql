IF OBJECT_ID('@cohort_database_schema.@cohort_table', 'U') IS NOT NULL
	DROP TABLE @cohort_database_schema.@cohort_table;
	
--HINT DISTRIBUTE_ON_KEY(subject_id)
SELECT TOP @sample_size CAST(1 AS INT) AS cohort_definition_id,
	ROW_NUMBER() OVER(ORDER BY person_id, observation_period_end_date) AS row_id,
	person_id AS subject_id,
	observation_period_end_date AS cohort_start_date,
	observation_period_end_date AS cohort_end_date
INTO @cohort_database_schema.@cohort_table
FROM @cdm_database_schema.observation_period
WHERE DATEDIFF(DAY, observation_period_start_date, observation_period_end_date) > 365
ORDER BY NEWID();


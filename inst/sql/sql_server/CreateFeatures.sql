IF OBJECT_ID('tempdb..#drug_groups', 'U') IS NOT NULL
	DROP TABLE #drug_groups;

SELECT DISTINCT descendant_concept_id,
	ancestor_concept_id
INTO #drug_groups
FROM @cdm_database_schema.concept_ancestor
INNER JOIN @cdm_database_schema.concept
	ON ancestor_concept_id = concept_id
WHERE (
		(
			vocabulary_id = 'ATC'
			AND LEN(concept_code) IN (1, 3, 4, 5)
			)
		OR (
			standard_concept = 'S'
			AND domain_id = 'Drug'
			AND concept_class_id = 'Ingredient'
			)
		)
	AND concept_id != 0;

IF OBJECT_ID('tempdb..#condition_groups', 'U') IS NOT NULL
	DROP TABLE #condition_groups;

SELECT DISTINCT descendant_concept_id,
	ancestor_concept_id
INTO #condition_groups
FROM @cdm_database_schema.concept_ancestor
INNER JOIN (
	SELECT concept_id
	FROM @cdm_database_schema.concept
	INNER JOIN (
		SELECT *
		FROM @cdm_database_schema.concept_ancestor
		WHERE ancestor_concept_id = 441840 /* SNOMED clinical finding */
			AND (
				min_levels_of_separation > 2
				OR descendant_concept_id IN (433736, 433595, 441408, 72404, 192671, 137977, 434621, 437312, 439847, 4171917, 438555, 4299449, 375258, 76784, 40483532, 4145627, 434157, 433778, 258449, 313878)
				)
		) TEMP
		ON concept_id = descendant_concept_id
	WHERE concept_name NOT LIKE '%finding'
		AND concept_name NOT LIKE 'Disorder of%'
		AND concept_name NOT LIKE 'Finding of%'
		AND concept_name NOT LIKE 'Disease of%'
		AND concept_name NOT LIKE 'Injury of%'
		AND concept_name NOT LIKE '%by site'
		AND concept_name NOT LIKE '%by body site'
		AND concept_name NOT LIKE '%by mechanism'
		AND concept_name NOT LIKE '%of body region'
		AND concept_name NOT LIKE '%of anatomical site'
		AND concept_name NOT LIKE '%of specific body structure%'
		AND domain_id = 'Condition'
	) valid_groups
	ON ancestor_concept_id = valid_groups.concept_id;

IF OBJECT_ID('tempdb..#drug_features', 'U') IS NOT NULL
	DROP TABLE #drug_features;

--HINT DISTRIBUTE_ON_KEY(subject_id)	
SELECT row_id,
	subject_id,
	ancestor_concept_id AS covariate_id,
	COUNT(*) AS covariate_value
INTO #drug_features
FROM @cdm_database_schema.drug_exposure
INNER JOIN #drug_groups
	ON drug_concept_id = descendant_concept_id
INNER JOIN @cohort_database_schema.@cohort_table cohort
	ON person_id = subject_id
		AND drug_exposure_start_date <= cohort_start_date
		AND drug_exposure_start_date >= DATEADD(DAY, - 365, cohort_start_date)
GROUP BY row_id,
	subject_id,
	ancestor_concept_id;
	
IF OBJECT_ID('tempdb..#condition_features', 'U') IS NOT NULL
	DROP TABLE #condition_features;
	
--HINT DISTRIBUTE_ON_KEY(subject_id)	
SELECT row_id,
	subject_id,
	ancestor_concept_id AS covariate_id,
	COUNT(*) AS covariate_value
INTO #condition_features
FROM @cdm_database_schema.condition_occurrence
INNER JOIN #condition_groups
	ON condition_concept_id = descendant_concept_id
INNER JOIN @cohort_database_schema.@cohort_table cohort
	ON person_id = subject_id
		AND condition_start_date <= cohort_start_date
		AND condition_start_date >= DATEADD(DAY, - 365, cohort_start_date)
GROUP BY row_id,
	subject_id,
	ancestor_concept_id;

IF OBJECT_ID('tempdb..#procedure_features', 'U') IS NOT NULL
	DROP TABLE #procedure_features;
	
--HINT DISTRIBUTE_ON_KEY(subject_id)	
SELECT row_id,
	subject_id,
	procedure_concept_id AS covariate_id,
	COUNT(*) AS covariate_value
INTO #procedure_features
FROM @cdm_database_schema.procedure_occurrence
INNER JOIN @cohort_database_schema.@cohort_table cohort
	ON person_id = subject_id
		AND procedure_date <= cohort_start_date
		AND procedure_date >= DATEADD(DAY, - 365, cohort_start_date)
GROUP BY row_id,
	subject_id,
	procedure_concept_id;
	
IF OBJECT_ID('tempdb..#measurement_features', 'U') IS NOT NULL
	DROP TABLE #measurement_features;
	
--HINT DISTRIBUTE_ON_KEY(subject_id)	
SELECT row_id,
	subject_id,
	measurement_concept_id AS covariate_id,
	COUNT(*) AS covariate_value
INTO #measurement_features
FROM @cdm_database_schema.measurement
INNER JOIN @cohort_database_schema.@cohort_table cohort
	ON person_id = subject_id
		AND measurement_date <= cohort_start_date
		AND measurement_date >= DATEADD(DAY, - 365, cohort_start_date)
GROUP BY row_id,
	subject_id,
	measurement_concept_id;
	
IF OBJECT_ID('tempdb..#observation_features', 'U') IS NOT NULL
	DROP TABLE #observation_features;
	
--HINT DISTRIBUTE_ON_KEY(subject_id)	
SELECT row_id,
	subject_id,
	observation_concept_id AS covariate_id,
	COUNT(*) AS covariate_value
INTO #observation_features
FROM @cdm_database_schema.observation
INNER JOIN @cohort_database_schema.@cohort_table cohort
	ON person_id = subject_id
		AND observation_date <= cohort_start_date
		AND observation_date >= DATEADD(DAY, - 365, cohort_start_date)
GROUP BY row_id,
	subject_id,
	observation_concept_id;

IF OBJECT_ID('tempdb..#features', 'U') IS NOT NULL
	DROP TABLE #features;	
	
--HINT DISTRIBUTE_ON_KEY(subject_id)
SELECT row_id,
	subject_id,
	covariate_id,
	covariate_value
INTO #features
FROM (
	SELECT row_id,
		subject_id,
		covariate_id,
		covariate_value
	FROM #drug_features
	
	UNION ALL
	
	SELECT row_id,
		subject_id,
		covariate_id,
		covariate_value
	FROM #condition_features
	
	UNION ALL
	
	SELECT row_id,
		subject_id,
		covariate_id,
		covariate_value
	FROM #procedure_features
	
	UNION ALL
	
	SELECT row_id,
		subject_id,
		covariate_id,
		covariate_value
	FROM #measurement_features
	
	UNION ALL
	
	SELECT row_id,
		subject_id,
		covariate_id,
		covariate_value
	FROM #observation_features
	) TEMP;

IF OBJECT_ID('tempdb..#feature_ref', 'U') IS NOT NULL
	DROP TABLE #feature_ref;

SELECT concept_id AS covariate_id,
	domain_id,
	concept_name
INTO #feature_ref
FROM @cdm_database_schema.concept
WHERE concept_id IN (
		SELECT DISTINCT covariate_id
		FROM #features
		);

TRUNCATE TABLE #drug_groups;

DROP TABLE #drug_groups;

TRUNCATE TABLE #condition_groups;

DROP TABLE #condition_groups;

TRUNCATE TABLE #drug_features;

DROP TABLE #drug_features;

TRUNCATE TABLE #condition_features;

DROP TABLE #condition_features;

TRUNCATE TABLE #procedure_features;

DROP TABLE #procedure_features;

TRUNCATE TABLE #measurement_features;

DROP TABLE #measurement_features;

TRUNCATE TABLE #observation_features;

DROP TABLE #observation_features;

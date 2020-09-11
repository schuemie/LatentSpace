# Copyright 2020 Observational Health Data Sciences and Informatics
#
# This file is part of LatentSpace
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

#' @export
constructFeatures <- function(connectionDetails,
                              cdmDatabaseSchema,
                              cohortDatabaseSchema,
                              cohortTable,
                              outputFolder,
                              oracleTempSchema = NULL,
                              sampleSize = 100000) {


  sql <- SqlRender::loadRenderTranslateSql(sqlFilename = "CreateFeatures.sql",
                                           packageName = "LatentSpace",
                                           dbms = connectionDetails$dbms,
                                           cohort_database_schema = cohortDatabaseSchema,
                                           cohort_table = cohortTable,
                                           cdm_database_schema = cdmDatabaseSchema,
                                           oracleTempSchema = oracleTempSchema)
  writeLines(sql)
  connection <- DatabaseConnector::connect(connectionDetails)
  on.exit(DatabaseConnector::disconnect(connection))
  ParallelLogger::logInfo("Constructing features on server")
  DatabaseConnector::executeSql(connection, sql)

  ParallelLogger::logInfo("Downloading features from server")
  features <- DatabaseConnector::querySql(connection, "SELECT row_id, covariate_id, covariate_value FROM #features;", snakeCaseToCamelCase = TRUE)
  featureRef <- DatabaseConnector::querySql(connection, "SELECT * FROM #feature_ref;", snakeCaseToCamelCase = TRUE)

  sql <- SqlRender::loadRenderTranslateSql(sqlFilename = "DropTempFeatureTables.sql",
                                           packageName = "LatentSpace",
                                           dbms = connectionDetails$dbms,
                                           cohort_database_schema = cohortDatabaseSchema,
                                           cohort_table = cohortTable,
                                           cdm_database_schema = cdmDatabaseSchema,
                                           oracleTempSchema = oracleTempSchema)
  DatabaseConnector::executeSql(connection, sql, progressBar = FALSE, reportOverallTime = FALSE)
  features <- filter(features, .data$covariateId != 0)
  featureRef <- filter(featureRef, .data$covariateId != 0)
  saveRDS(features, file.path(outputFolder, "Features.rds"))
  saveRDS(featureRef, file.path(outputFolder, "FeatureRef.rds"))

  # Old code: using FeatureExtraction, so binary, no counts:
  #
  #   covariateSettings <- FeatureExtraction::createCovariateSettings(useDemographicsGender = TRUE,
  #                                                                   useDemographicsAgeGroup = TRUE,
  #                                                                   useConditionGroupEraLongTerm = TRUE,
  #                                                                   useDrugGroupEraLongTerm = TRUE,
  #                                                                   useProcedureOccurrenceLongTerm = TRUE,
  #                                                                   useObservationLongTerm = TRUE,
  #                                                                   useMeasurementLongTerm = TRUE)
  #   covariateData <- FeatureExtraction::getDbCovariateData(connectionDetails = connectionDetails,
  #                                                          oracleTempSchema = oracleTempSchema,
  #                                                          cohortDatabaseSchema = cohortDatabaseSchema,
  #                                                          cohortTable = cohortTable,
  #                                                          cohortId = 1,
  #                                                          cdmDatabaseSchema = cdmDatabaseSchema,
  #                                                          rowIdField = "row_id",
  #                                                          covariateSettings = covariateSettings)
  #   FeatureExtraction::saveCovariateData(covariateData, file.path(outputFolder, "CovariateData.zip"))


}

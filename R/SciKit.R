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
prepareForSciKit <- function(outputFolder) {
  features <- readRDS(file.path(outputFolder, "Features.rds"))
  featureRef <- readRDS(file.path(outputFolder, "FeatureRef.rds"))

  # Remap covariate IDs and row IDs so we start at 1, and have no gaps in numbers:
  oldCovariateIds <- unique(features$covariateId)
  newCovariateIds <- 0:(length(oldCovariateIds) - 1)
  oldRowIds <- unique(features$rowId)
  newRowIds <- 0:(length(oldRowIds) - 1)
  features$covariateId <- plyr::mapvalues(features$covariateId,
                                          oldCovariateIds,
                                          newCovariateIds,
                                          warn_missing = FALSE)
  features$rowId <- plyr::mapvalues(features$rowId,
                                    oldRowIds,
                                    newRowIds,
                                    warn_missing = FALSE)
  featureRef$covariateId <- plyr::mapvalues(featureRef$covariateId,
                                            oldCovariateIds,
                                            newCovariateIds,
                                            warn_missing = FALSE)

  # covariates <- covariates[covariates$rowId < 100, ]

  # Save to CSV files for SciKit:
  write.csv(features, file.path(outputFolder, "features.csv"), row.names = FALSE)
  write.csv(featureRef, file.path(outputFolder, "featureRef.csv"), row.names = FALSE)

  # Old code: using FeatureExtraction, so binary, no counts:
  # covariateData <- FeatureExtraction::loadCovariateData(file.path(outputFolder, "CovariateData.zip"))
  # covariateData <- FeatureExtraction::tidyCovariateData(covariateData)
  #
  # covariates <- collect(covariateData$covariates)
  # covariateRef <- collect(covariateData$covariateRef)
  #
  # oldCovariateIds <- unique(covariates$covariateId)
  # newCovariateIds <- 0:(length(oldCovariateIds) - 1)
  # oldRowIds <- unique(covariates$rowId)
  # newRowIds <- 0:(length(oldRowIds) - 1)
  #
  # covariates$covariateId <- plyr::mapvalues(covariates$covariateId,
  #                                           oldCovariateIds,
  #                                           newCovariateIds,
  #                                           warn_missing = FALSE)
  # covariates$rowId <- plyr::mapvalues(covariates$rowId,
  #                                     oldRowIds,
  #                                     newRowIds,
  #                                     warn_missing = FALSE)
  #
  #
  # write.csv(covariates, file.path(outputFolder, "covariates.csv"), row.names = FALSE)
  #
  # covariateRef$covariateId <- plyr::mapvalues(covariateRef$covariateId,
  #                                             oldCovariateIds,
  #                                             newCovariateIds,
  #                                             warn_missing = FALSE)
  # write.csv(covariateRef, file.path(outputFolder, "covariateRef.csv"), row.names = FALSE)


}

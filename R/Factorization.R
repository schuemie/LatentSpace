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
doFactorization <- function(outputFolder) {
  covariateData <- FeatureExtraction::loadCovariateData(file.path(outputFolder, "CovariateData.zip"))
  covariateData <- FeatureExtraction::tidyCovariateData(covariateData)

  covariates <- collect(covariateData$covariates)
  covariateRef <- collect(covariateData$covariateRef)
  covariateRef$covariateName <- gsub(".*: +", "", covariateRef$covariateName)
  start <- Sys.time()
  model <- poismf::poismf(covariates, k = 100, method = "tncg", nthreads = maxCores, niter = 100)
  delta <- Sys.time() - start
  writeLines(paste("Factorization took", signif(delta, 3), attr(delta, "units")))
  # a_vec  <- factors.single(model,
  #                          X[X$row_ix==2, c("col_ix","count")])
  #
  # A_full <- poismf::factors(model, covariates)
  # A_orig <- poismf::get.factor.matrices(model)$A


  loadFactors <- poismf::get.factor.matrices(model)$B
  covariateIds <- as.numeric(rownames(loadFactors))
  output <- NULL
  for (i in 1:ncol(loadFactors)) {
    x <- tibble(factorId = i,
                covariateId = covariateIds,
                weight = loadFactors[, i])
    x <- x %>%
      inner_join(covariateRef[, c("covariateId", "covariateName")], by = "covariateId") %>%
      arrange(desc(weight))
    x <- select(x, weight, covariateName)
    output <- bind_cols(output, x)
  }
  readr::write_csv(output, file.path(outputFolder, "factors.csv"))
}

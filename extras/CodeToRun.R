library(LatentSpace)
library(dplyr)

# options(andromedaTempFolder = "s:/andromedaTemp")
maxCores <- parallel::detectCores()
connectionDetails <- DatabaseConnector::createConnectionDetails(dbms = "pdw",
                                                                server = keyring::key_get("pdwServer"),
                                                                user = NULL,
                                                                password = NULL,
                                                                port = keyring::key_get("pdwPort"))
oracleTempSchema <- NULL

outputFolder <- "s:/LatentSpace"
cdmDatabaseSchema <- "CDM_OPTUM_PANTHER_V1157.dbo"
cohortDatabaseSchema <- "scratch.dbo"
cohortTable <- "mschuemi_temp"

dir.create(outputFolder)

createCohort(connectionDetails = connectionDetails,
             cdmDatabaseSchema = cdmDatabaseSchema,
             cohortDatabaseSchema = cohortDatabaseSchema,
             cohortTable = cohortTable,
             sampleSize = 100000)


constructFeatures(connectionDetails = connectionDetails,
                  cdmDatabaseSchema = cdmDatabaseSchema,
                  cohortDatabaseSchema = cohortDatabaseSchema,
                  cohortTable = cohortTable,
                  outputFolder = outputFolder,
                  oracleTempSchema = oracleTempSchema)

prepareForSciKit(outputFolder)

# Now run extras/SciKit.py manually

import numpy as np
import pandas as pd
from scipy.sparse import coo_matrix
from scipy import sparse
from sklearn.decomposition import TruncatedSVD, NMF, LatentDirichletAllocation
from sklearn.model_selection import GridSearchCV
import csv

trainCovariates = pd.read_csv("s:/LatentSpace/trainFeatures.csv", header = 0)
trainCovariates = coo_matrix((trainCovariates.covariateValue, (trainCovariates.rowId, trainCovariates.covariateId)))

testCovariates = pd.read_csv("s:/LatentSpace/testFeatures.csv", header = 0)
testCovariates = coo_matrix((testCovariates.covariateValue, (testCovariates.rowId, testCovariates.covariateId)))

results = pd.DataFrame({'nComponents': [10, 20, 40, 80, 160], 'll': [0.0, 0.0, 0.0, 0.0, 0.0], 'perplexity': [0.0, 0.0, 0.0, 0.0, 0.0]})


results = pd.DataFrame({'nComponents': [2048, 4096], 'll': [0.0, 0.0], 'perplexity': [0.0, 0.0]})

# results = pd.DataFrame({'nComponents': [10, 20], 'll': [0.0, 0.0], 'perplexity': [0.0, 0.0]})

for i in range(results.shape[0]):
	nComponent = results['nComponents'][i]
	print("nComponent: ", nComponent)
	lda = LatentDirichletAllocation(n_components = nComponent, max_iter = 200, learning_method = 'batch', random_state = 100, n_jobs = 32, verbose = 1, evaluate_every = 10)
	lda.fit(trainCovariates)
	results.at[i, 'll'] = lda.score(testCovariates)
	results.at[i, 'perplexity'] = lda.perplexity(testCovariates)
	print("Log Likelihood: ", results.at[i, 'll'])
	print("Perplexity: ", results.at[i, 'perplexity'])

results.to_csv (r's:/LatentSpace/gridSearchResults.csv', index = False, header = True)


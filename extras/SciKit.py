import numpy as np
import pandas as pd
from scipy.sparse import coo_matrix
from scipy import sparse
from sklearn.decomposition import TruncatedSVD, NMF, LatentDirichletAllocation
from sklearn.model_selection import GridSearchCV
import csv

covariates = pd.read_csv("s:/LatentSpace/features.csv", header = 0)
covaCoo = coo_matrix((covariates.covariateValue, (covariates.rowId, covariates.covariateId)))

###################### LDA ####################################

# Run LDA
lda = LatentDirichletAllocation(n_components=10,           # Number of topics
                                max_iter=50,               # Max learning iterations
                                learning_method='online',   
                                random_state=100,          # Random state
                                n_jobs = 32,               # Use all available CPUs
								                verbose = 1)


# lda = LatentDirichletAllocation(n_topics=100, max_iter=10, learning_method='online', learning_offset=50.,random_state=0, n_jobs=30)
# lda = LatentDirichletAllocation(n_topics=100, max_iter=50, learning_method='batch', random_state=0, verbose = 1)
#lda.fit(covaCoo)

# Grid search
search_params = {'n_components': [10, 20, 40, 80, 160]}
model = GridSearchCV(lda, param_grid = search_params, cv = 3, verbose = 1)
model.fit(covaCoo)
model.cv_results_

# Best Model
best_lda_model = model.best_estimator_
print("Best Model's Params: ", model.best_params_)
print("Best Log Likelihood Score: ", model.best_score_)
print("Model Perplexity: ", best_lda_model.perplexity(covaCoo))
lda = best_lda_model

# n_components=50,               
# max_iter=100, 
# batch_size=1000
# Log Likelyhood: Higher the better
print("Log Likelihood: ", lda.score(covaCoo))
# -51730955
# Perplexity: Lower the better. Perplexity = exp(-1. * log-likelihood per word)
print("Perplexity: ", lda.perplexity(covaCoo))
# 751.97

# n_components=10,               
# max_iter=10, 
# batch_size=1000
# Log Likelyhood: Higher the better
print("Log Likelihood: ", lda.score(covaCoo))
# -53695679
# Perplexity: Lower the better. Perplexity = exp(-1. * log-likelihood per word)
print("Perplexity: ", lda.perplexity(covaCoo))
# 967.03

# n_components=10,               
# max_iter=10, 
# batch_size=128
# Log Likelyhood: Higher the better
print("Log Likelihood: ", lda.score(covaCoo))
# -53863180
# Perplexity: Lower the better. Perplexity = exp(-1. * log-likelihood per word)
print("Perplexity: ", lda.perplexity(covaCoo))
# 987.99



covsLda = lda.transform(covaCoo)

np.savetxt("s:/LatentSpace/covsLda.csv", covsLda, delimiter = ",")

covsLda /= covsLda.sum(axis=1)[:, np.newaxis]
np.savetxt("s:/LatentSpace/covsLdaNorm.csv", covsLda, delimiter = ",")

components = lda.components_

with open('s:/LatentSpace/componentsLda.csv', 'w') as f:
	writer = csv.writer(f, lineterminator='\n')
	writer.writerow(['factorId', 'covariateId', 'value'])
	for factorId in range(len(components)):
		for covariateId in range(len(components[0])):
			writer.writerow([factorId, covariateId, components[factorId, covariateId]])

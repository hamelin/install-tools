#!/bin/bash -x
set -e
test -x "$1"

"$1" python <<-TEST
import datamapplot
import duckdb
import evoc
import fast_hdbscan
from sentence_transformers import SentenceTransformer
from hdbscan import HDBSCAN
import numpy as np
import pandas as pd
import umap
import vectorizers as vz
import vectorizers.transformers as vzt

mpnet = SentenceTransformer("sentence-transformers/all-mpnet-base-v2")
jina = SentenceTransformer("jinaai/jina-embeddings-v3", trust_remote_code=True)
sentences = [
    "Where is the heck is Carmen Sandiego?",
    "Colin ate a donut.",
    "Multiple sources confirm that the plane flipped on its back just before touching down."
]
for model in [mpnet, jina]:
    print(model.encode(sentences).shape)

ar = jina.encode(sentences)
datamap = umap.UMAP(metric="cosine", init="pca").fit_transform(ar)
print(datamap.shape)
TEST

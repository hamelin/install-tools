from sentence_transformers import SentenceTransformer
mpnet = SentenceTransformer("sentence-transformers/all-mpnet-base-v2")
jina = SentenceTransformer("jinaai/jina-embeddings-v3", trust_remote_code=True)

sentences = [
    "Where is the heck is Carmen Sandiego?",
    "Colin ate a donut.",
    "Multiple sources confirm that the plane flipped on its back just before touching down."
]
for model in [mpnet, jina]:
    print(model.encode(sentences).shape)

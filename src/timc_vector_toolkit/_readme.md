This package brings together the various libraries that the Tutte Institute
has built towards exploratory analysis, unsupervised learning and interactive
visualization for unstructured data. It includes the following individual
packages.

Learn more at <https://github.com/TutteInstitute>

***IMPORTANT***: this package includes the libraries described below as
dependencies without upper-bounding their versions.
As such, newer versions of the package are mainly produced when editing
the toolkit roster, and not necessarily when new versions of
its dependencies are released. Thus, do not mistake the age of this
package for dereliction.


----------------------
Vector space embedding
----------------------

**vectorizers**

Embeds various types of data into large-dimension vector spaces. This
includes data that consists in distributions on vector spaces,
which are embedded by the approximate resolution of optimal transport
problems.


-----------------------------------
Nearest neighbour network discovery
-----------------------------------

**pynndescent**

Builds the k-nearest neighbour graph of a set of high-dimension vectors
expressed as either dense or sparse arrays, under a large set of distances
and pseudo-metrics. Doubles as an in-memory index for querying neighbours
to arbitrary vectors.


-------------------
Dimension reduction
-------------------

**umap** (package name is umap-learn)

Uniform Manifold Approximation and Projection is a manifold learning
dimension reduction algorithm that preserves the local similarity
structure of a set of vectors. It works on both dense and sparse
vector arrays.


----------
Clustering
----------

**hdbscan**

Hierarchical Density-Based Spatial Clustering of Applications with Noise.
This clustering algorithm partitions a set of vectors into groups based on
mutual reachability distance, discarding outliers as noise.

**fast_hdbscan**

A new implementation of HDBSCAN optimized for runtime efficiency by
restricting computations to low-dimension vectors in Euclidean geometry.

**evoc**

Embedding Vector-Oriented Clustering is a new clustering algorithm that
streamlines and approximates the UMAP-HDBSCAN combo approach to clustering,
so as to compute high-quality clusterings of high-dimension vector sets
at a fraction of the computational cost.


-------------------------
Interactive visualization
-------------------------

**datamapplot**

Creates static plots and interactive views of 2D vectors and metadata,
with an emphasis on presentation aesthetics and interactive exploration
for insight discovery.

**toponymy**

Generates a multiresolution hierarchy of annotation labels for text
embeddings by querying a large language model with representative,
distinctive and contrastive characterizations of data clusters. These
labels are then useful for annotating data maps produced with
datamapplot.


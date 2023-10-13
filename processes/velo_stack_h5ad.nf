process VeloStackH5AD {
    
    publishDir "${params.outdir}/velo/${sample_id}", mode: 'symlink'
    conda "${params.conda.env}"

    input:
    tuple val(sample_id), path(cdna_h5ad), path(intron_h5ad)

    output:
    path("${sample_id}.h5ad"), emit: h5ad_ch

    script:
    """
    #!/usr/bin/env python

    import numpy as np
    import pandas as pd
    import scanpy as sc
    import anndata as ad
    from scipy.sparse import csr_matrix

    # Load input datasets
    introns = ad.read_h5ad("${intron_h5ad}")
    cdna = ad.read_h5ad("${cdna_h5ad}")

    # Determine Intersection of Axes
    obs_idx = introns.obs.index.intersection(cdna.obs.index)
    var_idx = introns.var.index.intersection(cdna.var.index)

    # Subset Datasets
    intron_intersection = introns[obs_idx][:, var_idx]
    cdna_intersection = cdna[obs_idx][:, var_idx]

    # Create Observation DataFrame
    df_obs = intron_intersection.obs.copy()
    df_var = intron_intersection.var.copy()

    # Create Velocity AnnData
    adata = ad.AnnData(
        X=cdna_intersection.X + intron_intersection.X,
        layers={
            'spliced': cdna_intersection.X,
            'unspliced': intron_intersection.X
        },
        obs=df_obs,
        var=df_var,
    )

    # Add Sample ID to Observation Metadata
    adata.obs['sample_id'] = "${sample_id}"

    # Write to File
    adata.write_h5ad("${sample_id}.h5ad")
    """
}


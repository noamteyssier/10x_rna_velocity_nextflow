process BuildH5AD {
    
    publishDir "${params.outdir}/${group}/counts/${sample_id}", mode: 'symlink'
    conda "${params.conda.env}"

    input:
    tuple val(sample_id), path(mtx)
    path(barcodes)
    path(genes)
    val(group)
    val(calculate)

    output:
    tuple val(sample_id), path("${sample_id}.${group}.h5ad"), emit: h5ad_ch

    script:
    """
    #!/usr/bin/env python

    import scanpy as sc
    import anndata as ad

    # Load data
    adata = sc.read_mtx("${mtx}")
    barcodes = open("${barcodes}").read().splitlines()
    genes = open("${genes}").read().splitlines()

    # Set index
    adata.obs.index = barcodes
    adata.var.index = genes

    # Calculate QC metrics
    if ${calculate}:
        sc.pp.calculate_qc_metrics(adata, inplace=True)

    # Add SampleID to obs
    adata.obs["sample_id"] = "${sample_id}"

    # Write to file
    adata.write_h5ad("${sample_id}.${group}.h5ad")
    """
}

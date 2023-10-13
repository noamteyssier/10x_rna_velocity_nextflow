process Merge {

    publishDir "${params.outdir}", mode: 'symlink'
    conda "${params.conda.env}"

    input:
    path(adata_filt_ch)
    path(g2s)

    output:
    path("adata.h5ad"), emit: h5ad_ch

    script:
    """
    #!/usr/bin/env python

    import scanpy as sc

    def build_g2s(t2g_path: str) -> dict:
        used = dict()
        g2s = dict()
        for line in open(t2g_path):
            record = line.strip().split('\t')
            tx = record[0]
            sym = record[1]
            if tx not in g2s:
                if sym == "":
                    g2s[tx] = tx
                else:
                    if sym not in used:
                        used[sym] = 0
                    else:
                        used[sym] += 1
                        sym += f"_{used[sym]}"
                    g2s[tx] = sym
        return g2s

    def concatenate_h5ads(path_list: list):
        adata = sc.concat(
            [sc.read_h5ad(i) for i in path_list],
            join='outer',
        )
        adata.obs_names_make_unique()
        return adata


    path_list = [i for i in "${adata_filt_ch}".split(" ")]
    adata = concatenate_h5ads(path_list)
    g2s = build_g2s("${g2s}")
    
    adata.var["ensembl_id"] = adata.var.index
    adata.var["gene_symbol"] = adata.var["ensembl_id"].map(g2s)
    adata.var.set_index("gene_symbol", inplace=True)
    adata.var_names_make_unique()

    # Calculate QC metrics
    sc.pp.calculate_qc_metrics(adata, inplace=True)

    adata.write_h5ad("adata.h5ad")
    """
}

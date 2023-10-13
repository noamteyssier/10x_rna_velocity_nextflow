process BUStoolsSort {
    
    publishDir "${params.outdir}/kb/${sample_id}", mode: 'symlink'

    input:
    tuple val(sample_id), path(unsorted_bus)

    output:
    tuple val(sample_id), path("output.sorted.bus"), emit: sorted_bus_ch

    script:
    """
    bustools sort \
        -t ${params.n_threads} \
        -m ${params.max_mem} \
        -o output.sorted.bus \
        ${unsorted_bus}
    """
}

process BUStoolsInspect {
    
    publishDir "${params.outdir}/kb/${sample_id}", mode: 'symlink'

    input:
    tuple val(sample_id), path(sorted_bus)
    path(ec)

    output:
    path("inspect.json")

    script:
    """
    bustools inspect \
        -o inspect.json \
        -e ${ec} \
        ${sorted_bus}
    """
}

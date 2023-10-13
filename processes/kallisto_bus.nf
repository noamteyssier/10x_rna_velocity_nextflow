process KallistoBUS {
    
    publishDir "${params.outdir}/kb/${sample_id}", mode: 'symlink'

    input:
    tuple val(sample_id), path(reads)
    path(index)
    val(tech)

    output:
    tuple val(sample_id), path("${sample_id}/output.bus"), emit: bus_ch
    path("${sample_id}/matrix.ec"), emit: ec_ch
    path("${sample_id}/transcripts.txt"), emit: transcripts_ch

    script:
    """
    kallisto bus -n -t ${params.n_threads} \
        -i ${index} \
        -o ${sample_id} \
        -x ${tech} \
        ${reads[0]} ${reads[1]}
    """
}

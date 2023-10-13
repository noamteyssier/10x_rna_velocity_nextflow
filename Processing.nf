#!/usr/bin/env nextflow

include { BuildH5AD } from "./processes/build_h5ad.nf"
include { BUStoolsSort } from "./processes/bustools_sort.nf"
include { BUStoolsInspect } from "./processes/bustools_inspect.nf"
include { BUStoolsCountVelo } from "./processes/bustools_count.nf"
include { KallistoBUS } from "./processes/kallisto_bus.nf"
include { Merge } from "./processes/merge.nf"
include { VeloStackH5AD } from "./processes/velo_stack_h5ad.nf"

workflow {

    // check for file existence
    index = file(params.kallisto.index, checkIfExists: true)
    t2g = file(params.kallisto.t2g, checkIfExists: true)
    intron_t2g = file(params.kallisto.intron_t2g, checkIfExists: true)
    cdna_t2g = file(params.kallisto.cdna_t2g, checkIfExists: true)
    g2s = file(params.kallisto.g2s, checkIfExists: true)
    reads = Channel
        .fromFilePairs (params.data.reads, checkIfExists: true)

    // Map reads to splici index
    bus = KallistoBUS(
        reads,
        index,
        params.kallisto.tech,
    )

    // Calculate mapping statistics
    BUStoolsInspect(
        bus.bus_ch,
        bus.ec_ch,
    )

    // Sort BUS file
    sorted = BUStoolsSort(
        bus.bus_ch,
    )

    proc_cdna = CountCDNA(
        sorted.sorted_bus_ch,
        bus.transcripts_ch,
        bus.ec_ch,
        cdna_t2g,
    )

    proc_intron = CountIntrons(
        sorted.sorted_bus_ch,
        bus.transcripts_ch,
        bus.ec_ch,
        intron_t2g,
    )

    // Merge h5ads
    intron_h5ad_ch = proc_intron.h5ad_ch
        .map { it -> [ it[0].replace("_intron", ""), it[1] ] }
    cdna_h5ad_ch = proc_cdna.h5ad_ch
        .map { it -> [ it[0].replace("_cdna", ""), it[1] ] }
    merged_ch = intron_h5ad_ch.join(cdna_h5ad_ch)

    // Stack both intronic and cDNA h5ads into single h5ads
    velo_stack = VeloStackH5AD(
        merged_ch,
    )

    // Merge all h5ads into a single h5ad
    merged = Merge(
        velo_stack.h5ad_ch.collect(),
        g2s,
    )

}

workflow CountCDNA {
    
    take:
        sorted_bus
        transcripts
        ec
        t2g
    main:
        counts = BUStoolsCountVelo(
            sorted_bus,
            transcripts,
            ec,
            t2g,
            "cdna",
        )

        h5ad = BuildH5AD(
            counts.mtx_ch,
            counts.barcodes_ch,
            counts.genes_ch,
            "cdna",
            "True",
        )

        h5ad_ch = h5ad.h5ad_ch

    emit:
        h5ad_ch

}

workflow CountIntrons {
    
    take:
        sorted_bus
        transcripts
        ec
        t2g
    main:
        counts = BUStoolsCountVelo(
            sorted_bus,
            transcripts,
            ec,
            t2g,
            "intron",
        )

        h5ad = BuildH5AD(
            counts.mtx_ch,
            counts.barcodes_ch,
            counts.genes_ch,
            "intron",
            "True",
        )

        h5ad_ch = h5ad.h5ad_ch

    emit:
        h5ad_ch

}

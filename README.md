# 10x_rna_velocity_nextflow

A nextflow pipeline for running RNA velocity splice aware mapping on 10X fastqs

## Dependencies

- [nextflow](https://www.nextflow.io/)
- [conda](https://docs.conda.io/projects/miniconda/en/latest/)
- [cargo](https://rustup.rs/)
- [kallisto](https://pachterlab.github.io/kallisto/download)
- [bustools](https://bustools.github.io/download)

This will specifically require that `kallisto`, and `bustools`
are in your `$PATH`.

### Optional Dependencies

These are dependencies used in preparing the index that are optional
but useful and used in this README.

- [ggetrs](https://noamteyssier.github.io/ggetrs/)
- [splici](https://github.com/noamteyssier/splici)
- [gtfjson](https://github.com/noamteyssier/gtfjson)
- [samtools](https://github.com/samtools/samtools)

### Installation

Once you have `cargo` installed and a conda environment setup
we can run the following batch install

```bash
cargo install ggetrs gtfjson splici
```

## Configuration

You can make changes to formats and settings in the `nextflow.config` file.

It is there that you can change the *per sample* number of threads and potential
changes to filepaths.

## Expected Files

This ships without the transcriptome index built (since it can be very large)

However, you can create it and all the transcript mapping files with a few commands:

> **Note:**
>
> This will use
> [`ggetrs`](https://noamteyssier.github.io/ggetrs/)
> and
> [`splici`](https://github.com/noamteyssier/splici)
> to download the reference data and to create the transcript/intronic reads respectively.
>
> It will also use `samtools` to create the fasta index (.fai) which is
> required to extract intervals from a fasta (used by `splici` to create
> the transcripts and intronic reads).

```bash
# Move into the metadata directory
cd data/meta/

# Download your species reference Genome and GTF with `ggetrs`
ggetrs ensembl ref -D -d gtf,dna -s mus_musculus

# Decompress the genome
gunzip Mus_musculus.GRCm39.dna.primary_assembly.fa.gz

# Index the genome
samtools faidx Mus_musculus.GRCm39.dna.primary_assembly.fa

# Use splici to calculate and extract cDNA and intronic reads
# from the reference genome using annotations from the GTF
# using 8 threads for compression.
# splici will also generate the t2g (transcript to gene) mapping.
splici introns \
    -g Mus_musculus.GRCm39.110.gtf.gz \
    -f Mus_musculus.GRCm39.dna.primary_assembly.fa \
    -o splici.fasta.gz \
    -j 8

# We will then create the intron and cDNA t2g files.
grep "S$" t2g.tsv > cdna.t2g.tsv
grep "U$" t2g.tsv > introns.t2g.tsv

# We'll then use gtfjson (`gj`) to build a gene to symbol map
gj map -m g2s -i Mus_musculus.GRCm39.110.gtf.gz -o g2s.tsv;

# Create the kallisto index using the splici sequences
kallisto index -i index.idx splici.fasta.gz

# Move back to the root of the directory
cd ../../
```

## Conda

This requires some python code for building `anndata` files.

You can create the required environment with the bundled yaml:

```bash
conda env create --file envs/env.yaml
conda activate velocity_workflow
```

## Usage

Once you have all the prerequisite metadata in `data/meta/` and
you have your 10X reads in `data/sequence/` and your conda environment activated
then you can run the following:

```bash
nextflow run -resume Processing.nf
```

## Results

There will be a single anndata (`results/adata.h5ad`) that will be created
that will contain the concatenated count matrices of all individual samples.

Within that anndata there will be a column in `adata.obs` that reflects the sample
names.

All the results of the mapping will be in the `results/` directory that
will be created.

You can explore the `work/` directory to see intermediate steps and also
the commands used to generate everything.

All files in the `results` directory are symlinked from the `work` directory
so be careful not to delete it by accident.

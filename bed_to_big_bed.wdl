version 1.0

workflow B2BBwf {

  meta {
    author: "Filip Bartek"
    email: "filipbartek6417@gmail.com"
    description: "Converts bed to bigbed."
  }

  parameter_meta {
    bed_file: "Input bed for conversion."
    # ucsc_db_name: "The UCSC genome version for which the chrom.sizes fill be used."
    ucsc_url: "The UCSC genome url for chrom.sizes."
  }

  input {
    File bed_file
    # String ucsc_db_name
    String ucsc_url
  }

  call sortBed {
    input:
      bed_file = bed_file
  }

  call getChromSizes {
    input:
      # ucsc_db_name = ucsc_db_name
      ucsc_url = ucsc_url
  }

  call bedToBigBed {
    input:
      sorted_bed = sortBed.sorted_bed,
      chrom_sizes = getChromSizes.chrom_sizes
  }

  output {
    File bigBed_file = bedToBigBed.bigBed_file
  }

}

task sortBed {

  input {
    File bed_file
  }

  command <<<
    sort -k1,1 -k2,2n ${bed_file} > "sorted.bed"
  >>>

  output {
    File sorted_bed = "sorted.bed"
  }

  runtime {
    memory: "1 GB"
    cpu: 2
    disks: "local-disk 32 SSD"
    docker: "quay.io/biocontainers/samtools@sha256:9cd15e719101ae8808e4c3f152cca2bf06f9e1ad8551ed43c1e626cb6afdaa02" # 1.19.2--h50ea8bc_1
    preemptible: 1
  }

}

task getChromSizes {

  input {
    # Would be used with fetchChromSizes
    # String ucsc_db_name
    String ucsc_url
  }

  command <<<
    # I wanted to use this, but it apparently does not support
    # the t2t hs1 assembly, so it has to be uglier
    # wget http://hgdownload.soe.ucsc.edu/admin/exe/linux.x86_64/fetchChromSizes
    # chmod +x fetchChromSizes
    # ./fetchChromSizes ${ucsc_db_name} > chrom.sizes
    curl -o chrom.sizes ${ucsc_url}
  >>>

  output {
    File chrom_sizes = "chrom.sizes"
  }

  runtime {
    memory: "1 GB"
    cpu: 2
    disks: "local-disk 32 SSD"
    docker: "quay.io/biocontainers/samtools@sha256:9cd15e719101ae8808e4c3f152cca2bf06f9e1ad8551ed43c1e626cb6afdaa02" # 1.19.2--h50ea8bc_1
    preemptible: 1
  }

}

task bedToBigBed {

  input {
    File sorted_bed
    File chrom_sizes
  }

  command <<<
    wget http://hgdownload.soe.ucsc.edu/admin/exe/linux.x86_64/bedToBigBed
    chmod +x bedToBigBed
    ./bedToBigBed ${sorted_bed} ${chrom_sizes} result.bb
  >>>

  output {
    File bigBed_file = "result.bb"
  }

  runtime {
    memory: "1 GB"
    cpu: 2
    disks: "local-disk 32 SSD"
    docker: "quay.io/biocontainers/samtools@sha256:9cd15e719101ae8808e4c3f152cca2bf06f9e1ad8551ed43c1e626cb6afdaa02" # 1.19.2--h50ea8bc_1
    preemptible: 1
  }

}
#!/bin/bash -ue
bwa-mem2 mem -t 4 LG12.fasta A_33_FDSW202661760-1r_HTNK5DSXY_L3_sub_1.trimmed.fq.gz A_33_FDSW202661760-1r_HTNK5DSXY_L3_sub_2.trimmed.fq.gz | samtools sort -@ 4 -o A_33_FDSW202661760-1r_HTNK5DSXY_L3_sub.bam

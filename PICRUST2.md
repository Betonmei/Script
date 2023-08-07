# 安装

```
mamba create -n picrust2 -c bioconda -c conda-forge picrust2=2.5.2
mamba create -n picrust2 -c bioconda -c conda-forge picrust2
conda activate picrust2
```

# 运行

```
picrust2_pipeline.py -s seqs.fasta \
    -i table_filtered.biom \
    -o picrust2_out_pipeline \
    -p 16
```

# 结果分析

## 添加描述作为新列

```
add_descriptions.py -i EC_metagenome_out/pred_metagenome_unstrat.tsv.gz -m EC \
                    -o EC_metagenome_out/pred_metagenome_unstrat_descrip.tsv.gz
```

```
add_descriptions.py -i KO_metagenome_out/pred_metagenome_unstrat.tsv.gz -m KO \
                    -o KO_metagenome_out/pred_metagenome_unstrat_descrip.tsv.gz
```

```
add_descriptions.py -i pathways_out/path_abun_unstrat.tsv.gz -m METACYC \
                    -o pathways_out/path_abun_unstrat_descrip.tsv.gz
```

## 生成 kegg pathway丰度表
```
pathway_pipeline.py -i KO_metagenome_out/pred_metagenome_unstrat.tsv.gz \
    -o KEGG_pathways_out --no_regroup \
    --map KEGG_pathways_to_KO.tsv
```

## 添加功能描述
```
add_descriptions.py -i KEGG_pathways_out/path_abun_unstrat.tsv.gz \
    --custom_map_table KEGG_pathways_info.tsv.gz \
    -o KEGG_pathways_out/path_abun_unstrat_descrip.tsv.gz
```

## KEGG层级分析
```
git clone https://github.com/YongxinLiu/EasyMicrobiome

zcat KO_metagenome_out/pred_metagenome_unstrat.tsv.gz > KEGG.KO.txt
    python3 【summarizeAbundance.py】 \
      -i KEGG.KO.txt \
        -m 【KO1-4.txt】 \
        -c 2,3,4 -s ',+,+,' -n raw \
        -o KEGG
```

## 统计各层级特征数量

```
wc -l KEGG*
```


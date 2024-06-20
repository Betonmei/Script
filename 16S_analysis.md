# qiime2 安装

```
conda update conda
conda install wget
wget https://data.qiime2.org/distro/core/qiime2-2022.11-py38-linux-conda.yml
conda env create -n qiime2-2022.11 --file qiime2-2022.11-py38-linux-conda.yml
rm qiime2-2022.11-py38-linux-conda.yml
```

#激活
```
conda activate qiime2-2022.11
qiime --help
conda info --envs
```

#一、预处理

##【1】数据导入

### 双端数据导入

```
time qiime tools import \
--type 'SampleData[PairedEndSequencesWithQuality]' \
--input-path SampleData/manifest.csv \
--output-path  paired-end-demux.qza \
--input-format PairedEndFastqManifestPhred33
```

### 单端数据导入

```
time qiime tools import \
  --type 'SampleData[SequencesWithQuality]' \
  --input-path SampleData/manifest \
  --output-path single-end-demux.qza \
  --input-format SingleEndFastqManifestPhred33V2
```

##【2】去除引物
```
time qiime cutadapt trim-single \
--i-demultiplexed-sequences paired-end-demux.qza\
--p-front-f GAGTTTGATCCTGGCTCAG \
--p-front-r TGCTGCCTCCCGTAGGAGT \
--o-trimmed-sequences paired-demux.qza \
--verbose \
&> primer_trimming.log

qiime cutadapt trim-paired \
--i-demultiplexed-sequences paired-end-demux.qza \
--p-cores 8 --p-front-f AGAGTTTGATCCTGGCTCAG \
--p-front-r TGCTGCCTCCCGTAGGAGT \
--o-trimmed-sequences paired-demux.qza \  
--verbose \
&> primer_trimming.log
```

## 【3】可视化

### 双端可视化

```
time qiime demux summarize \
--i-data paired-end-demux.qza \
--o-visualization paired-end-demux.qzv
```

### 单端可视化

```
time qiime demux summarize \
--i-data single-end-demux-E4.qza \
--o-visualization single-end-demux-E4.qzv
```


##【4】deblur降噪
### 合并

```
time qiime vsearch merge-pairs \
  --i-demultiplexed-seqs paired-end-demux.qza \
  --o-merged-sequences merged.qza
```

### 可视化

```
time qiime demux summarize \
--i-data merged.qza \
--o-visualization merged.qzv
```

### 双端合并数据

```
time qiime quality-filter q-score \
--i-demux merged.qza \
--o-filtered-sequences merged-filtered.qza \
--o-filter-stats merged-filtered-stats.qza
```

#### 单端数据

```
time qiime quality-filter q-score \
--i-demux single-end-demux.qza \
--o-filtered-sequences filtered.qza \
--o-filter-stats filtered-stats.qza
```

### 可视化

#### 双端合并数据

```
time qiime metadata tabulate \
--m-input-file merged-filtered-stats.qza \ 
--o-visualization merged-filtered-stats.qzv
```

#### 单端

```
qiime metadata tabulate \
    --m-input-file filtered-stats.qza \
    --o-visualization filtered-stats.qza.qzv
```

### 降噪

```
time qiime deblur denoise-16S \
--i-demultiplexed-seqs merged-filtered.qza \
--p-trim-length 150 \
--p-sample-stats \
--o-representative-sequences rep-seqs.qza \
--o-table table.qza \
--o-stats deblur-stats.qza
```

```
time qiime deblur denoise-16S \
--i-demultiplexed-seqs filtered.qza \
--p-trim-length 150 \
--p-sample-stats \
--o-representative-sequences rep-seqs.qza \
--o-table table.qza \
--o-stats deblur-stats.qza
```

### 可视化

```
time qiime deblur visualize-stats \
--i-deblur-stats deblur-stats.qza \
--o-visualization deblur-stats.qzv
```

##【4】合并数据

### 特征表

```
time qiime feature-table merge \
--i-tables table-1.qza \
--i-tables table-2.qza \
--o-merged-table table.qza
```

###数据代表数列
```
time qiime feature-table merge-seqs \
--i-data rep-seqs-1.qza \
--i-data rep-seqs-2.qza \
--o-merged-data rep-seqs.qza
```

### 特征表和代表序列统计
```
time qiime feature-table summarize \
--i-table table.qza \
--o-visualization table.qzv \
--m-sample-metadata-file metadata.txt
```

```
time qiime feature-table tabulate-seqs \
--i-data rep-seqs.qza \
--o-visualization rep-seqs.qzv
```

## 【5】TSV生成

```
time qiime tools export \
  --input-path table.qza \
  --output-path exported-feature-table
```

```
biom convert -i exported-feature-table/feature-table.biom -o table.tsv --to-tsv --header-key taxonomy

biom convert -i feature-table.tsv -o table.biom --to-hdf5 --table-type="OTU table" --process-obs-metadata taxonomy
  
qiime tools import \
  --input-path table.biom \
  --type 'FeatureTable[Frequency]' \
  --input-format BIOMV210Format \
  --output-path table.qza
```



## 【6】数据处理

### 过滤至少在30个样品中存在的Feature，去除偶然的Feature

很多OTU/特征只在一个样品中出现，而在其他所有样品中均为零，这种情况一般认为是偶然因素的结果，不具有普遍性，有生物学意义的可能性也比较小，因此通常过滤掉他们，以减少下游分析工作量，降低结果的假阴性率。

```
qiime feature-table filter-features \
  --i-table table.qza \
  --p-min-samples 30 \
  --o-filtered-table filtered-30-table.qza
```

### 过滤低丰度

实验中会有大量低丰度的特征/OTU，它们会增加计算工作量和影响高丰度结果差异比较时FDR校正Pvalue，导致假阴性，通常需要选择一定的阈值进行筛选，常用的有相对丰度千分之五、千分之一、万分之五、万分之一；也可根据测序总量，reads频率的筛选阈值常用2、5、10等，大项目样本多数据量大，有时甚至超过100，推荐最小丰度为百万分之一

```
qiime feature-table filter-features \
  --i-table filtered-30-table.qza \
  --p-min-frequency 10 \
  --o-filtered-table filtered-30-10-table.qza
```

###样品中包括极少的特征，也可以过滤掉
```
qiime feature-table filter-samples \
  --i-table table.qza \
  --p-min-features 10 \
  --o-filtered-table feature-contingency-filtered-table.qza
```

###基于物种过滤
```
qiime taxa filter-table \
  --i-table table.qza \
  --i-taxonomy taxonomy.qza \
  --p-exclude mitochondria \
  --o-filtered-table table-no-mitochondria.qza
```

###q2-taxa插件提供了一种方法filter-seqs，用于根据功能的分类注释过滤代表序列FeatureData[Sequence]。
```
qiime taxa filter-seqs \
  --i-sequences sequences.qza \
  --i-taxonomy taxonomy.qza \
  --p-include p__ \
  --p-exclude mitochondria,chloroplast \
  --o-filtered-sequences sequences-with-phyla-no-mitochondria-no-chloroplast.qza
```

###保留包含门级注释的所有物种，但在其分类注释中排除包含线粒体或叶绿体的所有序列。排除宿主污染
```
qiime taxa filter-table \
  --i-table table.qza \
  --i-taxonomy taxonomy.qza \
  --p-mode exact \ #搜索词区分大小写，因此搜索词线粒体不会返回与搜索词线粒体相近的结果。
  --p-include p__ \
  --p-exclude mitochondria,chloroplast \
  --o-filtered-table table-with-phyla-no-mitochondria-no-chloroplast.qza
```

### 生成一个需要保留或剔除的样品列表(也可以手动编写文本文件)
```
echo SampleID > samples-to-keep.tsv
echo L1S8 >> samples-to-keep.tsv
echo L1S105 >> samples-to-keep.tsv
```

### 只保留指定的两个样品L1S8和L1S105

```
qiime feature-table filter-samples \
  --i-table table.qza \
  --m-metadata-file samples-to-keep.tsv \
  --o-filtered-table id-filtered-table.qza
```


##【7】构建进化树
```
time qiime phylogeny align-to-tree-mafft-fasttree \
--i-sequences rep-seqs.qza \
--o-alignment aligned-rep-seqs.qza \ #多序列比对结果
--o-masked-alignment masked-aligned-rep-seqs.qza \ #过滤去除高变区后的多序列比对结果
--o-rooted-tree rooted-tree.qza \ #有根树，用于多样性分析
--o-tree unrooted-tree.qza #无根树

time qiime phylogeny align-to-tree-mafft-fasttree \
--i-sequences rep-seqs.qza \
--o-alignment aligned-rep-seqs.qza \
--o-masked-alignment masked-aligned-rep-seqs.qza \
--o-rooted-tree rooted-tree.qza \
--o-tree unrooted-tree.qza
```

##【8】多样性分析
### 抽平

```
qiime feature-table rarefy \
  --i-table table.qza \
  --p-sampling-depth 10000 \
  --o-rarefied-table table-rarefied.qza
```

```
qiime feature-table summarize \
  --i-table table-rarefied.qza \
  --o-visualization table-rarefied.qzv\
  --m-sample-metadata-file metadata.txt
```

###计算核心多样性，采样深度通常选择最小值，来自table.qzv
```
time qiime diversity core-metrics-phylogenetic \
--i-phylogeny rooted-tree.qza \
--i-table table.qza \
--p-sampling-depth 10000 \
--m-metadata-file metadata.txt \
--output-dir core-metrics-results
```

### 稀疏曲线

```
time qiime diversity alpha-rarefaction \
--i-table table.qza \
--i-phylogeny rooted-tree.qza \
--p-max-depth 10000 \
--m-metadata-file metadata.txt \
--o-visualization alpha-rarefaction.qzv
```

### Alpha多样性

香农指数（Shannon‘s）群落丰富度的定量度量，包括丰富度和均匀度
observed OTUs，群落丰富度的定性度量，只包括丰富度
Faith’s系统发育多样性，特征之间的系统发育关系的群落丰富度的定性量度
均匀度Evenness/ Pielou‘s均匀度，群落均匀度的度量

可选的alpha指数有faith_pd、shannon、observed_features、evenness

```
index=faith_pd
qiime diversity alpha-group-significance \
  --i-alpha-diversity core-metrics-results/${index}_vector.qza \
  --m-metadata-file metadata.txt \
  --o-visualization core-metrics-results/${index}-group-significance.qzv
```

### Beta多样性

Jaccard距离（群落差异的定性度量，只考虑种类，不考虑丰度）
Bray-Curtis距离。群落差异的定量度量，较常用
非加权UniFrac距离，特征之间的系统发育关系的群落定性度量
加权UniFrac距离，特征之间的系统发育关系的群落差异定量度量

可选的beta指数有 unweighted_unifrac、bray_curtis、weighted_unifrac和jaccard

```
distance=bray_curtis
column=group
qiime diversity beta-group-significance \
  --i-distance-matrix core-metrics-results/${distance}_distance_matrix.qza \
  --m-metadata-file metadata.txt\
  --m-metadata-column ${column} \
  --o-visualization core-metrics-results/${distance}-${column}-significance.qzv \
  --p-pairwise
```



##【9】物种注释

###物种注释数据训练集

```
wget -c ftp://greengenes.microbio.me/greengenes_release/gg_13_5/gg_13_8_otus.tar.gz
wget -c http://210.75.224.110/db/GreenGenes/gg_13_8_otus.tar.gz
tar -zxvf gg_13_8_otus.tar.gz
```

###使用rep_set文件中的99_otus.fasta数据和taxonomy中的99_OTU_taxonomy.txt数据作为参考物种注释
#### 导入参考序列

```
qiime tools import \
--type 'FeatureData[Sequence]' \
--input-path gg_13_8_otus/rep_set/99_otus.fasta \
--output-path 99_otus.qza
```

#### 导入物种分类信息
```
qiime tools import \
--type 'FeatureData[Taxonomy]' \
--input-format HeaderlessTSVTaxonomyFormat \
--input-path gg_13_8_otus/taxonomy/99_otu_taxonomy.txt \
--output-path ref-taxonomy.qza
```

### Train the classifier（训练分类器）全长
```
time qiime feature-classifier fit-classifier-naive-bayes \
--i-reference-reads 99_otus.qza \
--i-reference-taxonomy ref-taxonomy.qza \
--o-classifier classifier_gg_13_8_99.qza
```

### 引物提取参考序列的扩增区段 Extract reference reads
常用Greengenes 13_8 99% OTUs from 515F-806R region of sequences（分类器描述），提供测序的引物序列，截取对应的区域进行比对，达到分类的目的。

```
time qiime feature-classifier extract-reads \
--i-sequences 99_otus.qza \
--p-f-primer GTGCCAGCMGCCGCGGTAA \
--p-r-primer GGACTACHVGGGTWTCTAAT \
--o-reads ref-seqs.qza
```

```
time qiime feature-classifier fit-classifier-naive-bayes \
--i-reference-reads ref-seqs.qza \
--i-reference-taxonomy ref-taxonomy.qza \
--o-classifier classifier_gg_13_8_99_V4.qza
```

###物种注释
```
time qiime feature-classifier classify-sklearn \
--i-classifier classifier_gg_13_8_99_V4.qza \
--i-reads rep-seqs.qza \
--o-classification taxonomy.qza
```

###可视化物种注释
```
time qiime metadata tabulate \
--m-input-file taxonomy.qza \
--o-visualization taxonomy.qzv
```

```
qiime vsearch cluster-features-closed-reference \
 --i-sequences rep-seqs.qza \
 --i-table table.qza \
 --i-reference-sequences classifier_gg_13_8_99_V4.qza \
 --p-perc-identity 0.99 \
 --p-threads 10 \
 --output-dir ref_99_otu
```

###堆叠柱状图
```
time qiime taxa barplot \
--i-table table.qza \
--i-taxonomy taxonomy.qza \
--m-metadata-file metadata.txt \
--o-visualization taxa-bar-plots.qzv
```

##【10】差异分析
### 格式化特征表，添加伪计数

```
time qiime composition add-pseudocount \
--i-table table.qza \
--o-composition-table comp-table.qza
```

### 计算差异特征，指定分组类型比较

```
time qiime composition ancom \
--i-table comp-table.qza \
--m-metadata-file metadata.txt \
--m-metadata-column group \
--o-visualization ancom-group.qzv
```

###种属水平合并并统计(在属水平重叠合并)
```
time qiime taxa collapse \
--i-table table.qza \
--i-taxonomy taxonomy.qza \
--p-level 6 \
--o-collapsed-table table-l6.qza
```

### 格式化特征表，添加伪计数

```
time qiime composition add-pseudocount \
--i-table table-l6.qza \
--o-composition-table comp-table-l6.qza
```

### 计算种属差异，指定分组类型比较

```
time qiime composition ancom \
--i-table comp-table-l6.qza \
--m-metadata-file metadata.txt \
--m-metadata-column group \
--o-visualization l6-ancom-group.qzv
```
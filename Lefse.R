rm(list=ls())
setwd('F:\\16S_UC_CLOCK\\Lefse')
pacman::p_load(tidyverse,microeco,magrittr)

feature_table <- read.csv('feature_table.csv', row.names = 1)
sample_table <- read.csv('sample_table.csv', row.names = 1)
tax_table <- read.csv('tax_table.csv', row.names = 1)

head(feature_table)[1:6,1:6]; head(sample_table)[1:6, ]; head(tax_table)[,1:6]

# 创建microtable对象
dataset <- microtable$new(sample_table = sample_table,
                          otu_table = feature_table, 
                          tax_table = tax_table)
dataset

# 执行lefse分析
lefse <- trans_diff$new(dataset = dataset, 
                        method = "lefse", 
                        group = "Group", 
                        alpha = 0.01, 
                        lefse_subgroup = NULL)
# 查看分析结果
head(lefse$res_diff)

# 绘制前30个具有最高LDA（log10）的分类单元的差异特征柱状图
lefse$plot_diff_bar(use_number = 1:30, 
                    width = 0.8, 
                    group_order = c("control", "UC")) +
  ggsci::scale_color_npg() +
  ggsci::scale_fill_npg()

# 展示前200个分类单元和前50个特征
# 需要调用ggtree包
lefse$plot_diff_cladogram(use_taxa_num = 200, 
                          use_feature_num = 50, 
                          clade_label_level = 5, 
                          group_order = c("UC", "control"))

use_labels <- c("c__Deltaproteobacteria", "c__Actinobacteria", "o__Rhizobiales", "p__Proteobacteria", "p__Bacteroidetes", 
                "o__Micrococcales", "p__Acidobacteria", "p__Verrucomicrobia", "p__Firmicutes", 
                "p__Chloroflexi", "c__Acidobacteria", "c__Gammaproteobacteria", "c__Betaproteobacteria", "c__KD4-96",
                "c__Bacilli", "o__Gemmatimonadales", "f__Gemmatimonadaceae", "o__Bacillales", "o__Rhodobacterales")
# then use parameter select_show_labels to show
lefse$plot_diff_cladogram(use_taxa_num = 200, 
                          use_feature_num = 50, 
                          select_show_labels = use_labels)
Coab

 library(psych)

 library(Hmisc)

 genes <-read.csv("g.path.ibs-d.csv", header = TRUE, row.names = 1)

 spearman_results <- rcorr(as.matrix(genes[,-1]), type="spearman")

 spearman_corr <- spearman_results$r

 spearman_p_values <- spearman_results$P

 print(spearman_corr)

 print(spearman_p_values)

 coccor <- corr.test(t(genes), use ="pairwise", method = "spearman", adjust = "fdr",alpha = 0.05)

 r<- coccor$r

 p<- coccor$p 

 adjusted_p_values <- p.adjust(p, method ="BH")

 r[p> 0.05 & abs(r) < 0.5] <- 0

 r<- replace(r, abs(r) < 0.5 | p > 0.05, 0)

 data_df <- as.data.frame(cor_p_values)

 num_variables <- dim(data_df)[1]

 correlation <- unlist(data_df)

 source_nodes <- rep(colnames(data_df), each= num_variables)

 target_nodes <- rep(row.names(data_df),times = num_variables)

 result <- data.frame(Source = source_nodes,Target = target_nodes, Correlation = correlation)

 write.csv(result, file = "g.path.li-c.genus.csv",row.names = FALSE)

 

library(WGCNA)

adjacency <- cor_matrix

TOM <- TOMsimilarity(adjacency)

geneTree <- hclust(as.dist(1-TOM),method = "average")

dynamicMods <- cutreeDynamic(

 dendro = geneTree,

 distM = as.matrix(1-TOM),

 deepSplit = 2,

 pamRespectsDendro = FALSE,

 minClusterSize = 30

)

plotDendroAndColors(

 geneTree,

 dynamicMods,

 "Dynamic Tree Cut",

 dendroLabels = FALSE,

 hang = 0.03,

 addGuide = TRUE,

 guideHang = 0.05

）

 

\#limma

 df<- read.csv("table-LI.csv", header = TRUE, row.names = 1)   

 group<-c(rep("LI",40),rep("HC",40))

 designtable<-model.matrix(~0+factor(group))

 colnames(designtable)<-levels(factor(group))

 rownames(designtable)<-colnames(df) 

 contrast.matrix=makeContrasts(IBS -HC,levels=designtable)

 fit<-lmFit(df,designtable) 

 if(is.data.frame(df) && is.numeric(df) && is.matrix(designtable)){

  fit <- lmFit(df, designtable)

 }else {

  print("wrong")

 } 

 fit2<-contrasts.fit(fit,contrast.matrix)

 fit2<-eBayes(fit2)

 DEG<-topTable(fit2,coef="IBS -HC",n=Inf) 

 DEG$group <- ifelse(DEG$P.Value > 0.05,"no_change",

​                     ifelse(DEG$logFC > 1,"up",

​                            ifelse(DEG$logFC< -1, "down", "no_change")))
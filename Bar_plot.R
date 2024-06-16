rm(list=ls())#clear Global Environment
setwd('M:\\Study\\ZWLZ\\QIIME')#设置工作路径

#安装包
install.packages("reshape2")
install.packages("ggplot2")
install.packages("ggprism")
install.packages("plyr")
#加载R包
library (reshape2)
library(ggplot2)
library(ggprism)
library(plyr)
###################属水平丰度计算及可视化#####################
#读取数据
df1 <- read.table(file="Genus.txt",sep="\t",header=T,check.names=FALSE)
#查看前6行
head(df1)
##利用循环处理具有重复的数据
#初始化
data<-aggregate(L ~ Tax,data=df1,sum) #根据组修改
#重命名
colnames(data)[2]<-"example"
for (i in colnames(df1)[2:length(colnames(df1))]){
  #计算每列的和
  data1<-aggregate(df1[,i]~Tax,data=df1,sum)
  colnames(data1)[2]<-i  
  #合并列
  data<-merge(data,data1,by="Tax")
  }
df2<-data[,-2]
rownames(df2)=df2$Tax#修改行名
df3=df2[,-1]#删除多的列

#计算物种总丰度并降序排列
df3$rowsum <- apply(df3,1,sum)
df4 <- df3[order (df3$rowsum,decreasing=TRUE),]

#求物种相对丰度
df6 <- apply(df4,2,function(x) x/sum(x))
#由于之间已经按照每行的和进行过升序排列，所以可以直接取前10行
df7 <-  df6[1:9,]
df8 <- 1-apply(df7, 2, sum) #计算剩下物种的总丰度
#合并数据
df9 <- rbind(df7,df8)
row.names(df9)[10]="Others"
#导出数据
write.table (df9, file ="genus.csv",sep =",", quote =FALSE)
#变量格式转换,宽数据转化为长数据,方便后续作图
df_genus <- melt(df9) #df_genus <- melt(df9[,-3])去除rowsums
names(df_genus)[1:2] <- c("Taxonomy","sample")  #修改列名

##绘图
p2<-ggplot(df_genus, aes( x = sample,y=100 * value,fill = Taxonomy))+#geom_col和geom_bar这两条命令都可以绘制堆叠柱形图
  geom_col(position = 'stack', width = 0.6)+#geom_bar(position = "stack", stat = "identity", width = 0.6) 
  scale_y_continuous(expand = c(0,0))+# 调整y轴属性，使柱子与X轴坐标接触
  labs(x="Samples",y="Relative Abundance(%)",#设置X轴和Y轴的名称以及添加标题
       fill="Taxonomy")+
  guides(fill=guide_legend(keywidth = 1, keyheight = 1)) +#修改图例的框大小
  theme_prism(palette = "candy_bright",
              base_fontface = "plain", # 字体样式，可选 bold, plain, italic
              base_family = "serif", # 字体格式，可选 serif, sans, mono, Arial等
              base_size = 16,  # 图形的字体大小
              base_line_size = 0.8, # 坐标轴的粗细
              axis_text_angle = 0)+ # 可选值有 0，45，90，270
  scale_fill_prism(palette = "summer")#使用ggprism包修改颜色
p2     


#################拼图#################
library("cowplot")
plot_grid(p1,p2, labels=c('A','B'), ncol=1, nrow=2)#拼图及标注

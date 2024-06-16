getwd()

##收缩压与年龄，线性关系
#散点图
plot(nhanes2$age,nhanes2$bpsystol,col="grey",pch=1,cex=1.2,xlab="Age",ylab="SBP")
#线性关系
abline(lm(bhanes2$bpsystol~nhanes$age),lwd=2,col="blue",lty=1)
#加权回归线性拟合
lines(lowess(nhanes2$age,nhanes2$bpsystol),col="red",lty=2)
#标题
title("Assocition of Age and SBP")
#图例
legend("topleft",legend = c("linear","Lowess"),col = c("blue","red"),lty = 1:2)

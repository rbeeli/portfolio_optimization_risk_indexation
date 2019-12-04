library(data.table)
library(plyr)
library(tictoc)
library(RColorBrewer)
library(zoo)

# break on warnings
options(warn=2)



# load all NASDAQ 100 stock returns
stock.rets.long <- fread('NASDAQ-100_stocks_monthly_long.csv', header=T)
setindex(stock.rets.long, permno)
setindex(stock.rets.long, date)
head(stock.rets.long)

stock.rets.long <- stock.rets.long[, c('date', 'permno', 'ret')]



####################################################
# returns
####################################################

# reshape data to wide format
stock.rets.wide <- dcast(stock.rets.long, date ~ permno, value.var=c('ret'))
cols <- colnames(stock.rets.wide)
setcolorder(stock.rets.wide, c('date', cols[!cols %in% c('date')]))

head(stock.rets.wide[, 1:20])
tail(stock.rets.wide[, 1:20])

# write to CSV file
fwrite(stock.rets.wide, 'NASDAQ-100_stocks_monthly_wide.csv', sep=';')



####################################################
# plots
####################################################

eq.rets = rowMeans(stock.rets.wide[, -c(1)], na.rm=T)

plot(cumprod(1 + eq.rets), type='l')
plot(rowSums(!is.na(stock.rets.wide)), type='l')

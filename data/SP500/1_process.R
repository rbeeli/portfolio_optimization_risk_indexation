library(data.table)
library(plyr)
library(tictoc)
library(RColorBrewer)
library(zoo)

# break on warnings
options(warn=2)



# load all S&P500 stock returns
sp500.stocks <- fread('sp500_stocks_monthly.csv', header=T)
setindex(sp500.stocks, permno)
setindex(sp500.stocks, date)
head(sp500.stocks)




####################################################
# correct CRSP delisting bias
####################################################

#  When a stock is delisted, we use the delisting return from CRSP, if available.
#  Otherwise, we assume the delisting return is -100%, unless the reason for delisting is
#  coded as 500 (reason unavailable), 520 (went to over-the-counter), 551-573, 580 (various reasons),
#  574 (bankruptcy), or 584 (does not meet exchange financial guidelines).
#  For these observations, we assume that the delisting return is -30%.

m0.codes <- c(100) # Issue still trading NYSE/NYSE MKT, NASDAQ, Arca or Bats.
m30.codes <- c(500, 520, 551:573, 574, 580, 584)
m30.counter <- 0
m100.counter <- 0

# correct delisting bias in CRSP data because of missing delisting return
for (i in which(!is.na(sp500.stocks$dlstcd) & is.na(sp500.stocks$dlret))) {
  if (sp500.stocks[i]$dlstcd %in% m30.codes) {
    # use -30% delisting return
    sp500.stocks[i]$dlret <- -0.3
    m30.counter <- m30.counter + 1
  }
  else if (!(sp500.stocks[i]$dlstcd %in% m0.codes)) {
    # use -100% delisting return
    sp500.stocks[i]$dlret <- -1.0
    m100.counter <- m100.counter + 1
  }
}

paste('-30% delisting corrections: ', m30.counter)
paste('-100% delisting corrections: ', m100.counter)

# apply delisting return to last trading day return
delisted <- which(!is.na(sp500.stocks$dlret))
sp500.stocks[delisted]$ret <- (1 + sp500.stocks[delisted]$ret) * (1 + sp500.stocks[delisted]$dlret) - 1




####################################################
# returns
####################################################

# reshape data to wide format
stocks.ret <- dcast(sp500.stocks, date ~ permno, value.var=c('ret'))
cols <- colnames(stocks.ret)
setcolorder(stocks.ret, c('date', cols[!cols %in% c('date')]))

head(stocks.ret[, 1:20])
tail(stocks.ret[, 1:20])

# write to CSV file
fwrite(stocks.ret, 'sp500_stock_returns.csv', sep=';')







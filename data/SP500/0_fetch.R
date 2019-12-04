library(RPostgres)
library(plyr)
library(data.table)
library(readr)

# break on warnings
options(warn=2)


# sample period
from <- '1972-01-31'
to <- '2019-08-31'


# connect to WRDS database
wrds <- dbConnect(Postgres(), host='wrds-pgdata.wharton.upenn.edu', port=9737, dbname='wrds', sslmode='require', user='rbeeli', password=read_file('../WRDS_pwd.txt'))


# query S&P 500 single stock returns including delisting information, market cap and volume
res <- dbSendQuery(wrds, paste0(
    "select b.permno, b.date, b.ret, d.dlret, d.dlstcd, (ABS(b.prc) * (b.shrout * 1000)) as cap, GREATEST(b.vol, 0) as vol, ABS(b.prc) as prc, (b.shrout * 1000) as shrout
       from crsp.msp500list a
       join crsp.msf b on b.permno=a.permno
  left join crsp.mse d on d.permno=b.permno and d.date=b.date and d.dlstcd is not null
      where b.date >= a.start and b.date <= a.ending
        and b.date >= '", from, "' and b.date <= '", to, "'
   order by b.date"))
sp500StocksData <- dbFetch(res, n=-1)
dbClearResult(res)


# query S&P 500 index returns
#   vwretd - Value-Weighted Return (includes distributions)
#   ewretd - Equal-Weighted Return (includes distributions)
res <- dbSendQuery(wrds, paste0(
  "select caldt as date, vwretd, ewretd
     from crsp.msp500
    where caldt >= '", from, "' and caldt <= '", to, "'"))
sp500IndexData <- dbFetch(res, n=-1)
dbClearResult(res)


# write to CSV files
fwrite(sp500IndexData, 'sp500_index_monthly.csv', sep=';')
fwrite(sp500StocksData, 'sp500_stocks_monthly.csv', sep=';')

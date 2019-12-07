library(RPostgres)
library(plyr)
library(data.table)
library(readr)

# break on warnings
options(warn=2)



# connect to WRDS database
wrds <- dbConnect(Postgres(), host='wrds-pgdata.wharton.upenn.edu', port=9737, dbname='wrds', sslmode='require', user='rbeeli', password=read_file('../WRDS_pwd.txt'))

# fetch returns of all NASDAQ 100 constituents returns    ich.gvkey, ich.iid, ich.from, ich.thru, a.*
res <- dbSendQuery(wrds, paste0("select *
                                from crsp.msf a
                                join crsp.ccmxpf_lnkhist b on a.permno=b.lpermno
                                join compm.idxcst_his ich on b.liid = ich.iid and b.gvkey = ich.gvkey
                                 and (ich.from <= b.linkenddt or b.linkenddt is null)
                                 and (ich.thru >= b.linkdt or ich.thru is null)
                                where ich.gvkeyx='000005'
                                  and b.linktype in ('LU', 'LC')
                                  and b.linkprim in ('P', 'C')
                                  and a.date >= b.linkdt
                                  and (a.date <= b.linkenddt or b.linkenddt is null)
                                  and (ich.from <= a.date)
                                  and (ich.thru >= a.date or ich.thru is null)
                                  and a.date >= '1972-01-31' and a.date <= '2019-08-31'"))
stocksData <- dbFetch(res, n=-1)
dbClearResult(res)



# # query S&P 500 index returns
# #   vwretd - Value-Weighted Return (includes distributions)
# #   ewretd - Equal-Weighted Return (includes distributions)
# res <- dbSendQuery(wrds, paste0(
#   "select caldt as date, vwretd, ewretd
#      from crsp.msp500
#     where caldt >= '", from, "' and caldt <= '", to, "'"))
# sp500IndexData <- dbFetch(res, n=-1)
# dbClearResult(res)


# write to CSV files
fwrite(stocksData, 'DJIA_stocks_monthly_long.csv', sep=';')





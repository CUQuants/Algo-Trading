##Created as an example of how to use alpaca, not meant for real trading use

import yfinance as yf
import time
from datetime import datetime, timedelta
from alpaca.trading.client import TradingClient
from alpaca.trading.requests import MarketOrderRequest
from alpaca.trading.enums import OrderSide, TimeInForce

#Account API keys from Alpaca
apiKey = "PK3MW7J8WINQUKNH7PMY"
secretKey = "8ePDTHMMF9KNd34mEM9Z3fDbIgaGRPhn6pRdnXEZ"

trading_client = TradingClient(apiKey, secretKey, paper=True)

##account = trading_client.get_account()
##for property_name, value in account:
  ##print(f"\"{property_name}\": {value}")

#Defining a function to create the strategy, takes in the ticker, a start and end date
def strategy(ticker):
   
   tickerData = yf.Ticker(ticker)

   tickerHistorical = tickerData.history(period='2d')

   currentOpen = tickerHistorical['Open'][1] #Getting Open data
   previousClose = tickerHistorical['Close'][0] #Getting Close data

   if currentOpen > previousClose: #If the stock opened higher, buy
      print("Buy")
      return 1
   elif currentOpen < previousClose: #If the stock opened lower, sell
      print("Sell")
      return 0
   else: #If the stock if flat, do nothing
      print("No trade")
      return -1

tickerSymbol = 'SPY'

result = strategy(tickerSymbol) #Calling the function and passing through arguments

if result == 1: #If our strategy says buy, send a buy order
   market_order_data = MarketOrderRequest(
                      symbol= tickerSymbol,
                      qty=10,
                      side=OrderSide.BUY,
                      time_in_force=TimeInForce.GTC
                  )
elif result == 0: #If our strategy says sell, send a sell order
   market_order_data = MarketOrderRequest(
                      symbol= tickerSymbol,
                      qty=10,
                      side=OrderSide.SELL,
                      time_in_force=TimeInForce.GTC
                  )
   

#market_order = trading_client.submit_order(market_order_data)
#for property_name, value in market_order:
 # print(f"\"{property_name}\": {value}")


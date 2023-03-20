#######################################
##                                   ##
##             CU Quants             ##
##          Moving Average           ##
##                                   ##
#######################################
## Developed by Ryan Watts
#!/usr/bin/env python
## imports IGNORE THIS
from alpaca.trading.client import TradingClient
from alpaca.trading.enums import OrderSide, TimeInForce
from alpaca.trading.requests import MarketOrderRequest

import alpaca_trade_api as tradeapi

import time

import pandas_datareader as web

import configparser


## Input your key and secret ids here
## DO NOT PUSH YOUR PRIVATE KEY
## Place your key in key.txt, it will not be pushed.
file = open("key.txt", 'r')
content = file.read()
data = content.split("\n") #split it into lines


key = data[1].split(" = ")[1]
secret = data[2].split(" = ")[1]

if key == "<YOUR KEY>" or secret == "<YOUR SECRET>":
  print("PLEASE UPDATE KEY AND SECRET IN key.txt")
  exit()

client = TradingClient(key, secret, paper=True)  ## IGNORE ME
account = dict(client.get_account())  ## IGNORE ME
api = tradeapi.REST(key, secret, "https://paper-api.alpaca.markets")
api.get_clock()
print("Starting....")
print("")

##
## Ignore This
##

def market_order(ticker, qty, order_side):
  if order_side == "buy":
    side = OrderSide.BUY
  elif order_side == "sell":
    side = OrderSide.SELL
  else:
    print("-------> !ERROR! <-------")
    print("INVALID SIDE PARM FOR market_order()")
    print("-------> !ERROR! <-------")
  order_details = MarketOrderRequest(symbol=ticker,
                                     qty=qty,
                                     side=side,
                                     time_in_force=TimeInForce.DAY)

  order = client.submit_order(order_data=order_details)
  for i in range(25):
    print("")
  print("-------------- ORDER SUBMITED --------------")
  print("TICKER: ", ticker)
  print("QUANITYT: ", qty)
  print("SIDE: ", order_side)
  print("--------------------------------------------")
  time.sleep(1)


##
## Stop Ignoring
##

##
##
##
## Moving Average Strategy
##
##
##

##
## Moving Average Settings
##
ticker = 'SPY'  ## Symbol you want to trade
trading_quantity = 200  ## Number of shares you want to trade

moving_average = True  ## Set to False if you do not want to use the moving average strategy, set to True if you do
time_between = 1  ## The time (in seconds) before each price is collected
total_data_points = 10  ## the number of data points collected

if moving_average:

  try:
    api.get_position(ticker)  ## Ignore me
  except:
    market_order(ticker, 1, "buy")
    print("Fixed Position Error. Run me again.")
    exit()
  
  ##position.__getattr__('qty')  ## Ignore me
  
  def should_buy(moving_avg, price):
    ##
    ## Function that determines if the bot should buy or not
    ##
    if moving_avg < price and float(position.__getattr__('qty')) <= 1:
      ##
      ##  If statement that checks if the moving average value is greater than the price
      ##  and if the account has a quantity of zero for the security. If both are true
      ##  then the bot will return True meaning it will buy.
      ##
      return True
    else:
      ##
      ##  Either one or both of the above conditions were False so the function returns False
      ##  Indicating it will not buy
      ##
      return False

  def should_sell(moving_avg, price):
    ##
    ## Function that determines if the bot should sell or not
    ##
    if moving_avg > price and float(position.__getattr__('qty')) > 1:
      ##
      ##  If statement that checks if the moving average value is less than the price
      ##  and if the account has a quantity greater than zero for the security. If both
      ##  are true then the bot will return True meaning it will sell.
      ##
      return True
    else:
      ##
      ##  Either one or both of the above conditions were False so the function returns False
      ##  Indicating it will not sell
      ##
      return False

  def average(list):
    ##
    ## Simple function that calculates the average based on a list of inputs
    ##
    sum = 0
    for i in list:
      sum = sum + i

    return (sum / len(list))

  ma_prices = []  ## Setting up an empty list

  moving_average = 0
  pos = api.get_position(ticker)
  if float(pos.__getattr__('qty')) > 1:
    has_bought = True
  else:
    has_bought = False
  while True:
    position = api.get_position(ticker)
    ##
    ## Loop that will run forever or until the program is disrupted
    ##
    current_price = web.get_quote_yahoo(ticker)["regularMarketPrice"][0]
    ##
    ## Function that gets the current price of the ticker chosen and saves
    ## it to a variable called 'current_prices
    ##
    if len(ma_prices) >= total_data_points:
      ##
      ## Simple if statement that checks if moving average has enough data points
      ##
      ma_prices.pop(0)
      ##
      ## Removes the first price collected
      ##
      ma_prices.append(float(current_price))
      ##
      ## Adds the most current price to the moving average
      ##
      moving_average = average(ma_prices)
      ##
      ## Calculates the moving average value
      ##
      if should_buy(moving_average, current_price) and not has_bought:
        ##
        ## Checks if the program should buy
        ##
        has_bought = True
        print("BUYING!")
        market_order(ticker, trading_quantity, 'buy')
        ##
        ## Function that sends a buy market order
        ##
      elif should_sell(moving_average, current_price) and has_bought:
        ##
        ## Checks if the program should buy
        ##
        has_bought = False
        print("SELLING")
        market_order(ticker, trading_quantity, 'sell')
        ##
        ## Function that sends a sell market order
        ##
      print("")
      print("------")
      print("Ticker: ", ticker)
      print("Moving Average: $", round(moving_average,2))
      print("Price $", current_price)
      print("Position: ", float(position.__getattr__('qty')))
      print("------")
      print("Should Buy? ", should_buy(moving_average, current_price))
      print("Should Sell? ", should_sell(moving_average, current_price))
      print("------")
      print("")
      ##
      ## Messaging system so the user is up-to-date
      ##
    else:
      ##
      ## The program does not have enough data points and so continues to collect
      ## prices
      ##
      print("Collecting Data...", )
      ma_prices.append(current_price)
      ##
      ## Adds the current price to the list of prices
      ##
    time.sleep(time_between)
    ##
    ## Wait however much time you intended between collecting data points
    ## Note, there are better ways to do this but putting a simple
    ## time.sleep() function is just a simple way to do it
    ##

##
##
##
## Your Strategy Goes Here
##
##
##

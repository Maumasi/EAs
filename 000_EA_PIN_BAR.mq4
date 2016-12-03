//+------------------------------------------------------------------+
//|                                               000_EA_PIN_BAR.mq4 |
//|                                          Copyright 2016, Maumasi |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, Maumasi"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+

input string Basic1="------------------------------";// :::::::::::::::: Money Management ::
extern double LOT_SIZE = 0.01;
extern double AVG_SPREAD = 3;
//extern double BREAK_ABOVE_FOR_SL = 0.15;
extern int BREAK_ABOVE_RATIO = 1;
input string spacer1 = " ";// |

input string Basic2=" Order Type Should Be Against The Trend ";// :::::::::::::::: Pending Orders ::
extern bool BUY_STOPS = true;
extern bool SELL_STOPS = true;
extern bool DIRECT_BUY_ORDERS = true;
extern bool DIRECT_SELL_ORDERS = true;
extern double REWARD_MULTIPLIER = 2;
extern double STOP_ORDER_REWARD_MULTIPLIER = 1;
extern double STOP_ORDER_RISK_DEVIDER = 2;
input string spacer2 = " ";// |

int OnInit()
  {
//---

//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---

  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick() {
	static int bar = 0;
	static int stopOrder = 0;
	if(isNewBar()) {
		if(!hasOpenOrder()) {
			bar = 0;
			if(pinBarFinder() > Bid) {
				pinBarSell(pinBarFinder());
			}

			if(pinBarFinder() < Bid) {
				pinBarBuy(pinBarFinder());
			}
		} else {
			//*
			bar++;
			int ticket = openOrderTicket();
			OrderSelect( ticket, SELECT_BY_TICKET);

			// close sell orders
			if(bar > bottomFractalIndex(1) && OrderType() == OP_SELL && OrderProfit() > 0) {
				closeOrders();
			}

			// close buy orders
			if(bar > topFractalIndex(1) && OrderType() == OP_BUY && OrderProfit() > 0) {
				closeOrders();
			}
			//*/
		}// has order
   } // new bar if

   breakEven();
  }
//+------------------------------------------------------------------+




int pinBarSell(double pinBarEnd) {
   double order = 0;
   double tp = 0;
   double sl = 0;
   double spread = (AVG_SPREAD * Point() * 10);
   double pip = (Point() * 10);
   double risk = 0;
   double reward = 0;

   double bs_sl = 0;
   double bs_tp = 0;
   double bs_op = 0;

   int sell = 0;
   int buyStop = 0;

   int fracRef = bottomFractalIndex(1);
   double fractal = bottomFractal(fracRef);



	order = Open[0];
	sl = pinBarEnd + spread;
	risk = MathFloor((sl - order) / Point()) * Point();
	reward = (risk * REWARD_MULTIPLIER) - spread;
	tp = order - reward;

	bs_sl = pinBarEnd - ((risk + pip) / STOP_ORDER_RISK_DEVIDER);
	bs_tp = pinBarEnd + (risk * STOP_ORDER_REWARD_MULTIPLIER) + spread;
	bs_op = pinBarEnd + pip;

	if(fracRef != 1) {

		if(DIRECT_SELL_ORDERS) {
			sell = sellOrder(sl, tp);
			orderFailSafe(sell);
		}


		if(BUY_STOPS) {
			buyStop = buyStop(bs_op, bs_sl, bs_tp);
			orderFailSafe(buyStop);

			// close sell stops above this new buy stop
			closePendingOrders(OP_SELLSTOP, bs_op);
		}

		Comment(
			"SELL at: ", order,
			"\nSL at: ", sl,
			"\nTP at: ", tp,
			"\n",
			"\nRisk in PIPs: ", (risk / (Point() * 10)),
			"\nReward in PIPs: ", (reward / (Point() * 10))
		);
	}
	return buyStop;
}


int pinBarBuy( double pinBarEnd) {
	double order = 0;
	double tp = 0;
	double sl = 0;
	double pip = (Point() * 10);
	double spread = (AVG_SPREAD * Point() * 10);
	double risk = 0;
	double reward = 0;

	int buy = 0;
	int sellStop = 0;

	double ss_sl = 0;
   	double ss_tp = 0;
   	double ss_op = 0;

   	int fracRef = topFractalIndex(1);
   	double fractal = topFractal(fracRef);

	order = Open[0];
	sl = pinBarEnd - spread;

	risk = MathFloor((order - sl) / Point()) * Point();
	reward = (risk * REWARD_MULTIPLIER) + spread;
	tp = order + reward;

	ss_sl = pinBarEnd + ((risk + pip) / STOP_ORDER_RISK_DEVIDER);
	ss_tp = pinBarEnd - (risk * STOP_ORDER_REWARD_MULTIPLIER) - spread;
	ss_op = pinBarEnd - pip;


	if(fracRef != 1) {

		if(DIRECT_SELL_ORDERS) {
			buy = buyOrder(sl, tp);
			orderFailSafe(buy);
		}

		if(SELL_STOPS) {
			sellStop = sellStop(ss_op, ss_sl, ss_tp);
			orderFailSafe(sellStop);
			// close sell stops above this new buy stop
			closePendingOrders(OP_BUYSTOP, ss_op);
		}

		Comment(
			"BUY at: ", Open[0],
			"\nSL at: ", sl,
			"\nTP at: ", tp,
			"\n",
			"\nRisk in PIPs: ", (risk / (Point() * 10)),
			"\nReward in PIPs: ", (reward / (Point() * 10))
		);
	}
	return sellStop;
}


double pinBarFinder() {
	double result = 0;
	int pinBar = 0;
	int lastFrac = 0;
	int lookBack = 7;
	int topFrac = topFractalIndex(1);
	int bottomFrac = bottomFractalIndex(1);
	double pinBarEnd = 0;
	bool pinPointingUp = false;
	bool clearLeft = true;

	if(topFrac > bottomFrac) {
		lastFrac = bottomFrac;
		pinBarEnd = Low[lastFrac];
		pinPointingUp = true;
	} else {
		lastFrac = topFrac;
		pinBarEnd = High[lastFrac];
	}

	if(pinBar(lastFrac) == 2 && topFrac == lastFrac) {
		Comment("Bullish pin bar Price at: ", pinBarEnd);
	} else if(pinBar(lastFrac) == 4 && bottomFrac == lastFrac) {
		Comment("Bearish pin bar Price at: ", pinBarEnd);
	}

	result = pinBarEnd;
	return result;
}




int pinBar(int bar) {
	int result = 0;

	double topWick = 0;
	double bottomWick = 0;
	double body = 0;
	double bodyAndNose = 0;
	double pinBar = 0;
	double nose = 0;

	double close = Close[bar];
	double open = Open[bar];
	double high = High[bar];
	double low = Low[bar];

	bool bull = false;
	bool isPinBar = false;
	bool hasNose = false;

	// bar direction
	if(close > open) {
		bull = true;
	}

	// determine wick length
	if(bull) {
		topWick = (high - close) / Point();
		bottomWick = (open - low) / Point();
		body = (close - close) / Point();
	} else {
		topWick = (close - low) / Point();
		bottomWick = (high - open) / Point();
		body = (open - close) / Point();
	}

	// find pin bar end
	if(topWick > bottomWick && bull) {
		bodyAndNose = body + bottomWick;
		pinBar = topWick;
		nose = bottomWick;
	} else if(topWick < bottomWick && bull) {
		bodyAndNose = body + topWick;
		pinBar = bottomWick;
		nose = topWick;
	}

	if(topWick > bottomWick && !bull) {
		bodyAndNose = body + bottomWick;
		pinBar = topWick;
		nose = bottomWick;
	} else if(topWick < bottomWick && !bull) {
		bodyAndNose = body + topWick;
		pinBar = bottomWick;
		nose = topWick;
	}

	isPinBar = ((pinBar / bodyAndNose) > 2.5);
	hasNose = true;

	// only use the last pin bar that is a fractal
	if(bar == 2) {

	}

	if(isPinBar && hasNose && pinBar == bottomWick && High[bar] == High[2]) {
		result = 2;
	} else if(isPinBar && hasNose && pinBar == topWick && Low[bar] == Low[2]) {
		result = 4;
	}
	return result;
}









double topFractal(int index) {
	double result = iFractals(NULL,0,MODE_UPPER,index);
	return result;
}

int topFractalIndex(int index) {
	double lastFractal = 0;
	int bar = 0;
	for( int i = index; i <  Bars; i++ ){
		lastFractal = iFractals(NULL,0,MODE_UPPER,i);

		if(lastFractal != 0) {
			bar = i;
			break;
		}
	}
	return bar;
}



double bottomFractal(int index) {
	double result = iFractals(NULL,0,MODE_LOWER,index);
   return result;
}

int bottomFractalIndex(int index) {
	double lastFractal = 0;
	int bar = 0;
	for( int i = index; i <  Bars; i++ ){
		lastFractal = iFractals(NULL,0,MODE_LOWER,i);

		if(lastFractal != 0) {
			bar = i;
			break;
		}
	}
	return bar;
}




// check for a new bar instance
bool isNewBar() {
   static datetime lastBarTime = Time[1];

   bool result = false;
   int fri = 5;
   bool isFirstFirdayOfMonth = ((Day() <= 7) && (DayOfWeek() == 5));
   int sat = 6;

   if(lastBarTime != Time[0]) {
      result = true;

      // update bar time for next iteration of code
      lastBarTime = Time[0];
   }

   // prevent EA from trading on the first Friday of the month
   if(isFirstFirdayOfMonth) {
      result = false;
   }
   return result;
}


bool isNotFriday() {
   bool result = true;
   int fri = 5;
   bool isFirday = (DayOfWeek() == fri);

   if(isFirday) {
      result = false;
   }

   return result;
}



bool hasOpenOrder() {
   bool result = false;
   string pair = Symbol();
   int totalOrders = OrdersTotal();

   double profit = 0.0;
   string symbol = "";

   for( int i = 0; i < totalOrders; i++ ){
      bool order = OrderSelect(i, SELECT_BY_POS);

      // all relative to selected order
      symbol = OrderSymbol();
      profit = OrderProfit();
      bool charHasOpenOrder = (symbol == pair && profit != 0.0);

      if(charHasOpenOrder) {
         lookUpOrderFailSafe(order, i);
         result = true;
         break;
      } // if
   } // for loop

   return result;
}



int MagicNum() {
   int finalID = 0;
   double num1 = MathRand();
   double num2 = MathRand();
   double sampleNum = num1 / num2;
   double rawID = sampleNum + 1;

   int twoDigitNum = 10;
   while(rawID > twoDigitNum) {
      rawID--;
   }

   finalID = (rawID * 1000000);
   return finalID;
}




void breakEven() {
   double risk = 0;
   double currentProfit = 0;
   bool isOneToOne = false;

   if(hasOpenOrder()) {
      int ticket = openOrderTicket();
      bool foundOrder = OrderSelect(ticket, SELECT_BY_TICKET);
      lookUpOrderFailSafe(foundOrder, ticket);
      double newStopLoss = OrderOpenPrice();
      risk = MathFloor((MathAbs(OrderOpenPrice() - OrderStopLoss())) / Point()) * Point();

      if(OrderType() == OP_BUY) {
         currentProfit = MathFloor((MathAbs(OrderOpenPrice() - Bid)) / Point()) * Point();
         if(currentProfit >= (risk / BREAK_ABOVE_RATIO)) {
            newStopLoss += (Point() * 10);
            isOneToOne = true;
         }

         if(OrderTakeProfit() == 0) {

         }
      }

      if(OrderType() == OP_SELL) {
         currentProfit = MathFloor((MathAbs(OrderOpenPrice() - Ask)) / Point()) * Point();
         if(currentProfit >= (risk / BREAK_ABOVE_RATIO)) {
            newStopLoss -= (Point() * 10);
            isOneToOne = true;
         }
      }

      if(isOneToOne) {
         adjustStoploss(newStopLoss);
      }
   }
}




void adjustStoploss(double stopLoss) {
   int ticket = openOrderTicket();
   lookUpOrderFailSafe(OrderSelect(ticket, SELECT_BY_TICKET), ticket);

   bool modify = OrderModify(
      ticket, // ticket
      OrderOpenPrice(),
      stopLoss,
      OrderTakeProfit(),
      0,
      clrViolet
   );

   orderFailSafe(modify);
}



bool orderFailSafe(int ticket) {
   bool result = false;
   if(ticket < 0) {
      Alert("Error: Order failed : ", GetLastError());
   } else if(ticket != 0) {
      result = true;
      Alert("Your order on ", Symbol()," has ticket#: ", ticket);
   }
   return result;
}


int openOrderTicket() {
   int result = 0;
   string pair = Symbol();
   int totalOrders = OrdersTotal();

   double profit = 0.0;
   string symbol = "";

   for( int i = 0; i < totalOrders; i++ ){
      bool order = OrderSelect(i, SELECT_BY_POS);
      // all relative to selected order
      symbol = OrderSymbol();
      profit = OrderProfit();
      bool charHasOpenOrder = (symbol == pair && profit != 0.0);

      if(charHasOpenOrder) {
         lookUpOrderFailSafe(order, i);
         result = OrderTicket();
         break;
      } // if
   } // for loop

   return result;
}



bool lookUpOrderFailSafe(bool isOrder, int orderPosition) {
   bool result = false;
   if(isOrder) {
      result = true;
   } else {
      Print(
         "Failed to select order at position: ", orderPosition, "\nfor symbol: ", Symbol(),
         " | Error: ", GetLastError()
      );
   }
   return result;
}


void closeOrders() {
	for( int i = 0; i < OrdersTotal(); i++ ){
		closeDirectOrders(i);
	}
}



void closeDirectOrders(int index) {

   bool allOrders = OrderSelect(index, SELECT_BY_POS);

   // switch case would be better for this
   if(OrderType() == OP_BUY) {
      bool closed = OrderClose(
         OrderTicket(),      // ticket
         OrderLots(),        // volume
         Bid,       // close price
         10,    // slippage
         clrViolet  // color
      );
   } else if(OrderType() == OP_BUYSTOP) {
      bool closed = OrderClose(
         OrderTicket(),      // ticket
         OrderLots(),        // volume
         Bid,       // close price
         10,    // slippage
         clrViolet  // color
      );
   } else if(OrderType() == OP_SELL) {
      bool closed = OrderClose(
         OrderTicket(),      // ticket
         OrderLots(),        // volume
         Ask,       // close price
         10,    // slippage
         clrViolet  // color
      );
   } else if(OrderType() == OP_SELLSTOP) {
      bool closed = OrderClose(
         OrderTicket(),      // ticket
         OrderLots(),        // volume
         Ask,       // close price
         10,    // slippage
         clrViolet  // color
      );
  	}
}



// call to make a sell order
int sellOrder(double stopLoss, double takeProfit) {

   string comment = "Order created at server time: " + string(Time[0]);
   int slippage = 10;
   int friday = 5;
   int experation = 0;
   //double takeProfit = 0;
   // double stopLoss = Bid + (MAX_PIP_RISK * (Point() * 10));

   int ticket = OrderSend(
      Symbol(), // current chart
      OP_SELL,
      LOT_SIZE,
      Bid,
      slippage,
      stopLoss,
      takeProfit,
      comment,
      MagicNum(),
      experation,
      clrViolet
   );

   return ticket;
}


int sellStop(double price, double stopLoss, double takeProfit) {

   string comment = "Order created at server time: " + string(Time[0]);
   int slippage = 10;
   int friday = 5;
   int experation = 0;
   //double takeProfit = 0;
   // double stopLoss = Bid + (MAX_PIP_RISK * (Point() * 10));

   int ticket = OrderSend(
      Symbol(), // current chart
      OP_SELLSTOP,
      LOT_SIZE,
      price,
      slippage,
      stopLoss,
      takeProfit,
      comment,
      MagicNum(),
      experation,
      clrViolet
   );

   return ticket;
}


// call to make a buy order
int buyOrder(double stopLoss, double takeProfit) {

   string comment = "Order created at server time: " + string(Time[0]);
   int slippage = 10;
   int friday = 5;
   int experation = 0;
   //double takeProfit = 0.0;
   // double stopLoss = Bid + (MAX_PIP_RISK * (Point() * 10));

   int ticket = OrderSend(
      Symbol(), // current chart
      OP_BUY,
      LOT_SIZE,
      Ask,
      slippage,
      stopLoss,
      takeProfit,
      comment,
      MagicNum(),
      experation,
      clrGreen
   );

   return ticket;
}


int buyStop(double price, double stopLoss, double takeProfit) {

   string comment = "Order created at server time: " + string(Time[0]);
   int slippage = 10;
   int friday = 5;
   int experation = 0;
   //double takeProfit = 0.0;
   // double stopLoss = Bid + (MAX_PIP_RISK * (Point() * 10));

   int ticket = OrderSend(
      Symbol(), // current chart
      OP_BUYSTOP,
      LOT_SIZE,
      price,
      slippage,
      stopLoss,
      takeProfit,
      comment,
      MagicNum(),
      experation,
      clrGreen
   );

   return ticket;
}







void closePendingOrders(int marketOrder, double priceLevel) {
   int ticket = 0;
   string pair = Symbol();
   int totalOrders = OrdersTotal();

   double profit = 0.0;
   string symbol = "";

	for( int i = 0; i < totalOrders; i++ ){
		bool order = OrderSelect(i, SELECT_BY_POS);

		bool pendingType = (OrderType() == marketOrder);

		// all relative to selected order
		symbol = OrderSymbol();
		profit = OrderProfit();
		bool chartHasPendingOrder = (symbol == pair && profit == 0.0 && pendingType);

		if(marketOrder == OP_SELLSTOP && OrderType() == OP_SELLSTOP && chartHasPendingOrder) {
			if(OrderOpenPrice() < priceLevel) {
				ticket = OrderTicket();
				bool orderRemoved = OrderDelete(ticket);
				lookUpOrderFailSafe(orderRemoved, i);
			}
		}

		if(marketOrder == OP_BUYSTOP && OrderType() == OP_BUYSTOP && chartHasPendingOrder) {
			if(OrderOpenPrice() > priceLevel) {
				ticket = OrderTicket();
				bool orderRemoved = OrderDelete(ticket);
				lookUpOrderFailSafe(orderRemoved, i);
			}
		}
	} // for loop
}

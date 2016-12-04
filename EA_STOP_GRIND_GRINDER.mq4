//+------------------------------------------------------------------+
//|                                        EA_STOP_GRIND_GRINDER.mq4 |
//|                                          Copyright 2016, Maumasi |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, Maumasi"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict

input string Basic1="------------------------------";// :::::::::::::::: Money Management ::
extern double LOT_SIZE = 0.01;
extern double AVG_SPREAD = 3;
//extern double BREAK_ABOVE_FOR_SL = 0.15;
extern int BREAK_ABOVE_RATIO = 2;
extern bool AUTO_ADJUST_LOT_SIZE = true;
extern double ACCOUNT_PERCENT_RISK_FOR_AUTO_LOTS = 2;
input string spacer1 = " ";// |

input string Basic2=" Order Type Should Be Against The Trend ";// :::::::::::::::: Pending Orders ::
extern bool BUY_STOPS = true;
extern bool SELL_STOPS = true;
extern bool DIRECT_BUY_ORDERS = true;
extern bool DIRECT_SELL_ORDERS = true;
extern double REWARD_MULTIPLIER = 2;
extern double STOP_ORDER_REWARD_MULTIPLIER = 1;
extern double STOP_ORDER_RISK_DIVIDER = 2;
input string spacer2 = " ";// |

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
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
		//if(!hasOpenOrder()) {
			bar = 0;

         // make orders around the current price
			buildGrid();
		// close orders when an opposing fractal shows up
		} else {
			//*
			bar++;
			int ticket = openOrderTicket();
			OrderSelect( ticket, SELECT_BY_TICKET);

			// close sell orders
			if(bar > bottomFractalIndex(1) && OrderType() == OP_SELLSTOP && OrderProfit() > 0) {
				//closeOrders();
			}

			// close buy orders
			if(bar > topFractalIndex(1) && OrderType() == OP_BUYSTOP && OrderProfit() > 0) {
				//closeOrders();
			}
			//*/
		//}// has order
   } // new bar if

   breakEven();
}
//+------------------------------------------------------------------+














void buildGrid() {

   double pipOffset = 50;
   switch(Period()) {
      case PERIOD_M1:
         pipOffset = 10;
         break;
      case PERIOD_M5:
         pipOffset = 20;
         break;
      case PERIOD_M15:
         pipOffset = 30;
         break;
      case PERIOD_M30:
         pipOffset = 30;
         break;
      case PERIOD_H1:
         pipOffset = 40;
         break;
      default:
         break;
   }

	double sl = 0;
	double tp = 0;
	double op = 0;
	double grindLine = 0;
	double pips10 = Point() * pipOffset;
	double pip = Point() * 10;

	int bottom1 = bottomFractalIndex(1);
	int bottom2 = bottomFractalIndex(bottom1+1);
	int top1 = topFractalIndex(1);
	int top2 = topFractalIndex(top1 + 1);

	double bottomFrac1 = bottomFractal(bottom1);
	double bottomFrac2 = bottomFractal(bottom2);
	double topFrac1 = topFractal(top1);
	double topFrac2 = topFractal(top2);




	for( int i = 1; i < 3; i++ ){
		grindLine = ((pips10 * i) / 2);
		
		if(bottomFrac1 < bottomFrac2) {
			op = Bid - grindLine;
			sl = (op - pip) + grindLine;
			tp = op - grindLine;
			sellStop(op, sl, tp);
			closePendingOrders(OP_BUYSTOP, op, true);
		} else if(topFrac1 > topFrac2) {
			op = Ask + grindLine;
			sl = (op + pip) - grindLine;
			tp = op + grindLine;
			buyStop(op, sl, tp);
			closePendingOrders(OP_SELLSTOP, op, true);
		}
	}

	// close stop orders above current price
	//closePendingOrders(OP_SELLSTOP, Ask);
	//closePendingOrders(OP_BUYSTOP, Bid);
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

      if(OrderType() == OP_BUYSTOP) {
         currentProfit = MathFloor((MathAbs(OrderOpenPrice() - Bid)) / Point()) * Point();
         if(currentProfit >= (risk / BREAK_ABOVE_RATIO)) {
            newStopLoss += (Point() * 10);
            isOneToOne = true;
         }

         if(OrderTakeProfit() == 0) {

         }
      }

      if(OrderType() == OP_SELLSTOP) {
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


int sellStop(double price, double stopLoss, double takeProfit) {

   string comment = "Order created at server time: " + string(Time[0]);
   int slippage = 10;
   int friday = 5;
   int experation = 0;
   double lots = LOT_SIZE;

   if(AUTO_ADJUST_LOT_SIZE) {
      lots = autoLotSize();
   }

   int ticket = OrderSend(
      Symbol(), // current chart
      OP_SELLSTOP,
      lots,
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


int buyStop(double price, double stopLoss, double takeProfit) {

   string comment = "Order created at server time: " + string(Time[0]);
   int slippage = 10;
   int friday = 5;
   int experation = 0;
   double lots = LOT_SIZE;

   if(AUTO_ADJUST_LOT_SIZE) {
      lots = autoLotSize();
   }

   int ticket = OrderSend(
      Symbol(), // current chart
      OP_BUYSTOP,
      lots,
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







void closePendingOrders(int marketOrder, double priceLevel, bool allOrders = false) {
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
			if(OrderOpenPrice() < priceLevel && !allOrders) {
				ticket = OrderTicket();
				bool orderRemoved = OrderDelete(ticket);
				lookUpOrderFailSafe(orderRemoved, i);
			} else {
				ticket = OrderTicket();
				bool orderRemoved = OrderDelete(ticket);
				lookUpOrderFailSafe(orderRemoved, i);
			}
		}

		if(marketOrder == OP_SELLSTOP && OrderType() == OP_BUYSTOP && chartHasPendingOrder) {
			if(OrderOpenPrice() < priceLevel  && !allOrders) {
				ticket = OrderTicket();
				bool orderRemoved = OrderDelete(ticket);
				lookUpOrderFailSafe(orderRemoved, i);
			} 
		} else if(marketOrder == OP_BUYSTOP && OrderType() == OP_SELLSTOP && chartHasPendingOrder) {
         if(OrderOpenPrice() > priceLevel  && !allOrders) {
            ticket = OrderTicket();
            bool orderRemoved = OrderDelete(ticket);
            lookUpOrderFailSafe(orderRemoved, i);
         } 
      }
	} // for loop
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




double autoLotSize() {

   double risk = ACCOUNT_PERCENT_RISK_FOR_AUTO_LOTS;
   if(ACCOUNT_PERCENT_RISK_FOR_AUTO_LOTS > 5.25) {
      risk = 5.25;
   }
   double result = 0;
   double currentAccountSize = AccountBalance();
   double riskPercent = ((currentAccountSize * (risk / 100)) * 0.5);
   double newlotSize = (MathFloor((riskPercent * 0.01) * 100) / 100) * 0.5;
   //double risk = (newlotSize * 0.5);
   //double newlotSize = MarketInfo(Symbol(),MODE_TICKVALUE);
   newlotSize = newlotSize / MarketInfo(Symbol(),MODE_TICKVALUE);
   if(newlotSize < 0.01) {
      newlotSize = 0.01;
   }

   Comment(
      "Acct. size: ", currentAccountSize,
      "\n2% of account: ", riskPercent,
      "\nMax rist in lots: ", newlotSize
   );

   result = newlotSize;
   return result;
}







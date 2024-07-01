#property strict

#include <Trade\Trade.mqh>

input double Lots = 0.1;
input double StopLoss = 50;   
input double TakeProfit = 50;

CTrade trade;
double model[]; 

int OnInit()
{
   // Load the model
   int file_handle = FileOpen("rf_model.bin", FILE_BIN | FILE_READ | FILE_COMMON);
   if (file_handle == INVALID_HANDLE)
   {
      Print("Error opening file");
      return (INIT_FAILED);
   }

   int file_size = FileSize(file_handle);
   int elements = file_size / sizeof(double);

   ArrayResize(model, elements);
   FileReadArray(file_handle, model);
   FileClose(file_handle);

   Print("Model loaded successfully");
   return (INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
}

void OnTick()
{
   double features[15];

   // Add more features
   double rsi = iRSI(_Symbol, 0, 14, PRICE_CLOSE);
   Print("RSI: ", rsi);
   
   double adx = iADX(_Symbol, 0, 14);
   Print("ADX: ", adx);

   // Calculate lagged returns
   double lagged_returns = (iClose(_Symbol, 0, 1) - iClose(_Symbol, 0, 2)) / iClose(_Symbol, 0, 2);
   Print("Lagged Returns: ", lagged_returns);

   // Calculate rolling mean and rolling standard deviation
   double rolling_mean = iMA(_Symbol, 0, 20, 0, MODE_SMA, PRICE_CLOSE);
   Print("Rolling Mean: ", rolling_mean);
   
   double rolling_stddev = iStdDev(_Symbol, 0, 20, 0, MODE_SMA, PRICE_CLOSE);
   Print("Rolling StdDev: ", rolling_stddev);

   double msd = iStdDev(_Symbol, 0, 10, 0, MODE_SMA, PRICE_CLOSE);
   Print("MSD: ", msd);

   features[0] = rsi;
   features[1] = adx;
   features[2] = lagged_returns;
   features[3] = rolling_mean;
   features[4] = rolling_stddev;
   features[5] = msd;

   PreprocessData(features);

   for (int i = 0; i < ArraySize(features); i++) {
      Print("Preprocessed feature value: ", features[i]);
   }

   double prediction = 0.0;

   for (int i = 0; i < ArraySize(features); i++)
   {
      if (features[i] == features[i] && features[i] > -DBL_MAX && features[i] < DBL_MAX) {
         prediction += features[i] * model[i];
      } else {
         Print("Invalid feature value detected after preprocessing: ", features[i]);
         return;
      }
   }

   Print("Prediction: ", prediction);

   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);

   double sl = StopLoss;
   double tp = TakeProfit;

   double min_stop_level = SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
   if (min_stop_level > 0) {
      sl = MathMax(sl, min_stop_level * _Point);
      tp = MathMax(tp, min_stop_level * _Point);
   }

   Print("Calculated Stop Loss: ", sl);
   Print("Calculated Take Profit: ", tp);

   if (prediction > 0)
   {
      if (trade.Buy(Lots, _Symbol, ask, ask - sl * _Point, ask + tp * _Point, "Buy Order"))
      {
         Print("Buy order placed");
      }
      else
      {
         Print("Error placing buy order: ", GetLastError());
      }
   }
   else
   {
      if (trade.Sell(Lots, _Symbol, bid, bid + sl * _Point, bid - tp * _Point, "Sell Order"))
      {
         Print("Sell order placed");
      }
      else
      {
         Print("Error placing sell order: ", GetLastError());
      }
   }
}

void PreprocessData(double &features[])
{
   for (int i = 0; i < ArraySize(features); i++)
   {
      if (features[i] == features[i] && features[i] > -DBL_MAX && features[i] < DBL_MAX) {
         features[i] = (features[i] - 0.5) / 0.5;
      } else {
         features[i] = 0; // Fallback for invalid values
         Print("Replaced invalid feature value with 0: ", features[i]);
      }
   }
}

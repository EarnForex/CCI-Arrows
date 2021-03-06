//+------------------------------------------------------------------+
//|                                                       CCI Arrows |
//|                                 Copyright © 2009-2020, EarnForex |
//|                                       https://www.earnforex.com/ |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2009-2020, EarnForex"
#property link      "https://www.earnforex.com/metatrader-indicators/CCI-Arrows/"
#property version   "1.01"
#property description "CCI Arrows - direct trading signals based on CCI indicator."
#property description "Displays red and blue arrows for Short and Long signals."

#property indicator_chart_window
#property indicator_buffers 2
#property indicator_plots   2
#property indicator_color1  Blue
#property indicator_type1   DRAW_ARROW
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2
#property indicator_color2  Red
#property indicator_type2   DRAW_ARROW
#property indicator_style2  STYLE_SOLID
#property indicator_width2  2

double dUpCCIBuffer[];
double dDownCCIBuffer[];

input int CCI_Period = 14;  //This value sets the CCI Period Used, The default is 21

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
void OnInit()
{
   IndicatorSetString(INDICATOR_SHORTNAME, "CCI_Arrows(" + IntegerToString(CCI_Period) + ")");

//---- indicator buffers mapping  
   SetIndexBuffer(0, dUpCCIBuffer, INDICATOR_DATA);
   SetIndexBuffer(1, dDownCCIBuffer, INDICATOR_DATA);

//---- drawing settings
   PlotIndexSetInteger(0, PLOT_ARROW, 233);
   PlotIndexSetInteger(1, PLOT_ARROW, 234);

   PlotIndexSetString(0, PLOT_LABEL, "CCI Buy");
   PlotIndexSetString(1, PLOT_LABEL, "CCI Sell");
}

//+------------------------------------------------------------------+
//| Custom CCI Arrows                                                |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &High[],
                const double &Low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
{
   ArraySetAsSeries(High, true);
   ArraySetAsSeries(Low, true);

   double CCIBuffer[];
   int myCCI = iCCI(NULL, 0, CCI_Period, PRICE_CLOSE);
   CopyBuffer(myCCI, 0, 0, rates_total, CCIBuffer);

   for (int i = rates_total; i > 1; i--)
   {
      dUpCCIBuffer[rates_total - i + 1] = 0;
      dDownCCIBuffer[rates_total - i + 1] = 0;

      double myCCInow = CCIBuffer[rates_total - i + 1];
      double myCCI2 = CCIBuffer[rates_total - i]; //CCI One bar ago
      
      if (myCCInow >= 0) //is going long
      {
         if((myCCInow > 0) && (myCCI2 < 0)) //did it cross from below 50
         {
            dUpCCIBuffer[rates_total - i + 1] = Low[i] - 2 * _Point;
         }
      }
      
      if (myCCInow < 0)  //is going short
      {
         if((myCCInow < 0) && (myCCI2 > 0)) //did it cross from above 50
         {
            dDownCCIBuffer[rates_total - i + 1] = High[i] + 2 * _Point;
         }
      } 
   }
   
   return(rates_total);
}


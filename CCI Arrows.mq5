//+------------------------------------------------------------------+
//|                                                       CCI Arrows |
//|                                 Copyright © 2009-2022, EarnForex |
//|                                       https://www.earnforex.com/ |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2009-2022, EarnForex"
#property link      "https://www.earnforex.com/metatrader-indicators/CCI-Arrows/"
#property version   "1.02"

#property description "CCI arrows based on the cross of the zero line from below or from above."
#property description "Displays red and blue arrows for Short and Long signals."

#property indicator_chart_window
#property indicator_buffers 2
#property indicator_plots   2
#property indicator_color1  clrBlue
#property indicator_type1   DRAW_ARROW
#property indicator_width1  2
#property indicator_color2  clrRed
#property indicator_type2   DRAW_ARROW
#property indicator_width2  2

enum enum_candle_to_check
{
    Current,
    Previous
};

input int CCI_Period = 14;  // CCI Period
input bool EnableNativeAlerts = false;
input bool EnableEmailAlerts = false;
input bool EnablePushAlerts = false;
input enum_candle_to_check TriggerCandle = Previous;

double dUpCCIBuffer[];
double dDownCCIBuffer[];

int myCCI;

int LastAlertDirection;
datetime LastAlertTime;
bool FirstRun;

void OnInit()
{
    FirstRun = true;
    LastAlertDirection = 0;
    LastAlertTime = D'01.01.1970';

    IndicatorSetString(INDICATOR_SHORTNAME, "CCI Arrows (" + IntegerToString(CCI_Period) + ")");

    SetIndexBuffer(0, dUpCCIBuffer, INDICATOR_DATA);
    SetIndexBuffer(1, dDownCCIBuffer, INDICATOR_DATA);
    
    ArraySetAsSeries(dUpCCIBuffer, true);
    ArraySetAsSeries(dDownCCIBuffer, true);

    PlotIndexSetInteger(0, PLOT_ARROW, 233);
    PlotIndexSetInteger(1, PLOT_ARROW, 234);

    PlotIndexSetDouble(0, PLOT_EMPTY_VALUE, 0.0);
    PlotIndexSetDouble(1, PLOT_EMPTY_VALUE, 0.0);

    PlotIndexSetString(0, PLOT_LABEL, "CCI Buy");
    PlotIndexSetString(1, PLOT_LABEL, "CCI Sell");
    
    myCCI = iCCI(NULL, 0, CCI_Period, PRICE_CLOSE);
}

int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &Time[],
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
    ArraySetAsSeries(Time, true);

    int counted_bars = prev_calculated;
    if (counted_bars > 0) counted_bars--;
    int limit = rates_total - 1 - counted_bars;

    double CCIBuffer[];
    CopyBuffer(myCCI, 0, 0, rates_total, CCIBuffer);
    ArraySetAsSeries(CCIBuffer, true);

    if (limit == 1) limit++; // Always redraw latest two bars.
    for (int i = 0; i < limit; i++)
    {
        dUpCCIBuffer[i] = 0;
        dDownCCIBuffer[i] = 0;

        double myCCInow = CCIBuffer[i];
        double myCCI2 = CCIBuffer[i + 1]; // CCI one bar ago.

        if (myCCInow >= 0) // Is above zero.
        {
            if((myCCInow > 0) && (myCCI2 < 0)) // Did it cross from below 0?
            {
                double distance = (High[iHighest(Symbol(), Period(), MODE_HIGH, 20, i)] - Low[iLowest(Symbol(), Period(), MODE_LOW, 20, i)]) * 0.02;
                dUpCCIBuffer[i] = Low[i] - 2 * distance;
            }
        }

        if (myCCInow < 0) // Is below zero.
        {
            if((myCCInow < 0) && (myCCI2 > 0)) // Did it cross from above 0?
            {
                double distance = (High[iHighest(Symbol(), Period(), MODE_HIGH, 20, i)] - Low[iLowest(Symbol(), Period(), MODE_LOW, 20, i)]) * 0.02;
                dDownCCIBuffer[i] = High[i] + 2 * distance;
            }
        }
    }

    if ((!FirstRun) && ((EnableNativeAlerts) || (EnableEmailAlerts) || (EnablePushAlerts)))
    {
        if (((TriggerCandle > 0) && (Time[0] > LastAlertTime)) || (TriggerCandle == 0))
        {
            string Text;
            // Up arrow alert.
            if ((dUpCCIBuffer[TriggerCandle] != 0) && (LastAlertDirection != 1))
            {
                Text = "Up Arrow";
                if (EnableNativeAlerts) Alert(Text);
                Text = "CCI Arrows: " + Symbol() + " - " + StringSubstr(EnumToString((ENUM_TIMEFRAMES)Period()), 7) + " - " + Text + ".";
                if (EnableEmailAlerts) SendMail("CCI Arrows Alert", Text);
                if (EnablePushAlerts) SendNotification(Text);
                LastAlertTime = Time[0];
                LastAlertDirection = 1;
            }
            // Down arrow alert.
            if ((dDownCCIBuffer[TriggerCandle] != 0) && (LastAlertDirection != -1))
            {
                Text = "Down Arrow";
                if (EnableNativeAlerts) Alert(Text);
                Text = "CCI Arrows: " + Symbol() + " - " + StringSubstr(EnumToString((ENUM_TIMEFRAMES)Period()), 7) + " - " + Text + ".";
                if (EnableEmailAlerts) SendMail("CCI Arrows Alert", Text);
                if (EnablePushAlerts) SendNotification(Text);
                LastAlertTime = Time[0];
                LastAlertDirection = -1;
            }
        }
    }
    
    FirstRun = false;

    return rates_total;
}
//+------------------------------------------------------------------+
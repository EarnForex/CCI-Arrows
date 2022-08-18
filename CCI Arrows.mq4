//+------------------------------------------------------------------+
//|                                                       CCI Arrows |
//|                                 Copyright © 2009-2022, EarnForex |
//|                                       https://www.earnforex.com/ |
//+------------------------------------------------------------------+
#property copyright "Copyright © 2009-2022, EarnForex"
#property link      "https://www.earnforex.com/metatrader-indicators/CCI-Arrows/"
#property strict

#property description "CCI arrows based on the cross of the zero line from below or from above."
#property description "Displays red and blue arrows for Short and Long signals."

#property indicator_chart_window
#property indicator_buffers 2
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

int LastAlertDirection;
datetime LastAlertTime;
bool FirstRun;

void OnInit()
{
    FirstRun = true;
    LastAlertDirection = 0;
    LastAlertTime = D'01.01.1970';

    SetIndexBuffer(0, dUpCCIBuffer);
    SetIndexBuffer(1, dDownCCIBuffer);

    SetIndexArrow(0, 233); // 241 option for a different arrow head.
    SetIndexArrow(1, 234); // 242 option for a different arrow head.

    SetIndexEmptyValue(0, 0.0);
    SetIndexEmptyValue(1, 0.0);

    SetIndexLabel(0, "CCI Buy");
    SetIndexLabel(1, "CCI Sell");
    
    IndicatorShortName("CCI Arrows (" + IntegerToString(CCI_Period) + ")");
}

int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime& time[],
                const double& open[],
                const double& high[],
                const double& low[],
                const double& close[],
                const long& tick_volume[],
                const long& volume[],
                const int& spread[])
{
    int nCountedBars = IndicatorCounted();
    if (nCountedBars < 0) return -1;
    if (nCountedBars > 0)
    {
        nCountedBars--;
    }
    int nBars = Bars - nCountedBars - 1;

    for (int i = 0; i < nBars; i++)
    {
        dUpCCIBuffer[i] = 0;
        dDownCCIBuffer[i] = 0;

        double myCCInow = iCCI(NULL, 0, CCI_Period, PRICE_CLOSE, i);
        double myCCI2 = iCCI(NULL, 0, CCI_Period, PRICE_CLOSE, i + 1); // CCI one bar ago.

        if (myCCInow >= 0) // Is above zero.
        {
            if ((myCCInow > 0) && (myCCI2 < 0)) // Did it cross from below 0?
            {
                double distance = (High[iHighest(Symbol(), Period(), MODE_HIGH, 20, i)] - Low[iLowest(Symbol(), Period(), MODE_LOW, 20, i)]) * 0.02;
                dUpCCIBuffer[i] = Low[i] - 2 * distance;
            }
        }
        else if (myCCInow < 0) // Is below zero.
        {
            if ((myCCInow < 0) && (myCCI2 > 0)) // Did it cross from above 0?
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
                Text = "CCI Arrows: " + Symbol() + " - " + StringSubstr(EnumToString((ENUM_TIMEFRAMES)Period()), 7) + " - Up Arrow.";
                if (EnableNativeAlerts) Alert(Text);
                if (EnableEmailAlerts) SendMail("CCI Arrows Alert", Text);
                if (EnablePushAlerts) SendNotification(Text);
                LastAlertTime = Time[0];
                LastAlertDirection = 1;
            }
            // Down arrow alert.
            if ((dDownCCIBuffer[TriggerCandle] != 0) && (LastAlertDirection != -1))
            {
                Text = "CCI Arrows: " + Symbol() + " - " + StringSubstr(EnumToString((ENUM_TIMEFRAMES)Period()), 7) + " - Down Arrow.";
                if (EnableNativeAlerts) Alert(Text);
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
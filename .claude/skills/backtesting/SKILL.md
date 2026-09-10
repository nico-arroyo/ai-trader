---
name: backtesting
description: Use when writing, running, or interpreting backtests for trading strategies in this repo — covers the data conventions, the metrics that matter, and the pitfalls to guard against.
---

# Backtesting

## Workflow

1. Load historical data through the project's data layer (never read raw CSVs
   directly in a strategy).
2. Run the strategy in event-driven mode over the sample period.
3. Compute the standard metric set (below).
4. Compare against a buy-and-hold benchmark for the same instruments.

## Metrics to always report

- Total / annualized return
- Sharpe and Sortino ratio
- Maximum drawdown and its duration
- Win rate and profit factor
- Number of trades and average holding period
- Turnover and estimated transaction costs

## Pitfalls to check every time

- **Lookahead bias** — signals must use only data with timestamp <= decision time.
- **Survivorship bias** — include delisted instruments in the universe.
- **Overfitting** — prefer out-of-sample / walk-forward validation over a single
  in-sample run.
- **Unrealistic fills** — model slippage and commissions; no fills at the exact
  high/low.
- **Data snooping** — don't tune parameters on the test set.

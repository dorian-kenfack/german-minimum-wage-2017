# Data Dictionary

## Identifiers and Time Variables

| Variable | Description |
|------------------------------------|------------------------------------|
| `amr` | Labor market region (AMR) identifier |
| `amr_name` | Labor market region (AMR) name |
| `east` | Indicator for East Germany |
| `time` | Month-year identifier |
| `timeQ` | Quarter-year identifier |
| `timeH` | Half-year identifier |
| `year` | Calendar year |
| `month` | Calendar month |
| `post17` | Indicator equal to 1 from Q1/2017 onward |
| `post16` | Indicator equal to 1 from Q3/2016 onward |
| `weight_pop15` | Population aged 18–64 as of December 31, 2015; used as regression weight |
| `amr_proxy` | Employment-weighted average of district-level median wages within each AMR as of December 31, 2015 |

## Population Variables

| Variable | Description |
|------------------------------------|------------------------------------|
| `pop_totalle` | Total population as of December 31 |
| `pop_tot18_64` | Population aged 18–64 as of December 31 |
| `pop_tot18_34` | Population aged 18–34 as of December 31 |
| `pop_tot35_64` | Population aged 35–64 as of December 31 |
| `pop_share_1864_2015` | Share of population aged 18–64 as of December 31, 2015 (%) |

## Sectoral Employment Shares

| Variable | Description |
|------------------------------------|------------------------------------|
| `empl_share_agric_2015` | Employment share in agriculture, forestry, and fishing (%) |
| `empl_share_trade_2015` | Employment share in trade, transport, hospitality, information, and communication (%) |
| `empl_share_finan_2015` | Employment share in financial, insurance, business, and real-estate services (%) |
| `empl_share_publ_2015` | Employment share in public and other services, education, and health (%) |
| `empl_share_manutot_2015` | Employment share in manufacturing and construction (%) |

## Labor Market Outcomes

All employment outcomes are person counts rather than counts of employment relationships.

| Variable | Description |
|------------------------------------|------------------------------------|
| `svb_total` | Persons in employment subject to social security contributions |
| `geb_total` | Persons in marginal employment, including both exclusively marginally employed persons and persons with marginal employment as a secondary job |
| `geb_ausschl` | Persons exclusively in marginal employment |
| `svgeb_total` | Total persons in regular or exclusively marginal employment |
| `abs_total` | Total number of registered unemployed persons |
| `log_svb_total` | Log of `svb_total` |
| `log_geb_total` | Log of `geb_total` |
| `log_geb_ausschl` | Log of `geb_ausschl` |
| `log_svgeb_total` | Log of `svgeb_total` |
| `log_abs_total` | Log of `abs_tot` |

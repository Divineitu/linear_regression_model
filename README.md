# Predicting Unemployment in Developing Countries Using Education & Economic Data

## Mission
My mission focuses on Education and Job Creation. I wanted to explore whether education-related factors — like government spending on education, literacy rates, and school enrollment — can actually predict unemployment in developing countries.

## The Problem
Unemployment is a major challenge in developing nations, and education is often seen as the solution. But does the data back that up? This project uses regression models to predict a country's unemployment rate from its education and economic indicators, to see which factors matter most.

## Dataset
I used the **World Bank Education Statistics (EdStats)** dataset from [Kaggle](https://www.kaggle.com/datasets/theworldbank/education-statistics). The raw dataset has over 886,000 rows covering 4,000+ indicators across 200+ countries from 1970–2017. I filtered it down to **developing countries only** (low-income and middle-income economies) and selected indicators related to education spending, literacy, enrollment, and economic performance. After cleaning, I ended up with around 3,328 country-year observations and 24 features.

**Target variable:** Total unemployment rate (% of labor force)
**Key features:** Government education spending (% of GDP), literacy rates, school enrollment (primary/secondary/tertiary), GDP per capita, pupil-teacher ratios, labor force participation, population metrics

## Models
I compared three regression models:
- **Linear Regression** (+ gradient descent version using SGDRegressor)
- **Decision Tree Regressor**
- **Random Forest Regressor**

## Results
| Model | Test MSE | Test R² |
|-------|----------|---------|
| Linear Regression | 39.44 | 0.22 |
| SGD Regressor | 39.90 | 0.21 |
| Decision Tree | 7.71 | 0.85 |
| **Random Forest** | **1.80** | **0.96** |

Random Forest gave the best results with a Test R² of 0.96 and lowest MSE of 1.80. The trained model is saved as `best_model.pkl` and there's a `predict.py` script that loads it and makes predictions on new data.

**Note:** The raw `EdStatsData.csv` is 326MB and too large for GitHub. The notebook saves a processed `cleaned_data.csv` (1.2MB) in the data folder — if you run the notebook without the raw file, it'll automatically use the cleaned version instead.

## How to Run
1. Install dependencies: `pip install -r requirements.txt`
2. Open `summative/linear_regression/multivariate.ipynb` and run all cells
3. For standalone predictions: `python summative/linear_regression/predict.py`


API Endpoint: https://linear-regression-model-cios.onrender.com
Swagger UI: https://linear-regression-model-cios.onrender.com/docs

## How to Run the Mobile App
```bash
cd summative/FlutterApp
flutter pub get
flutter run


LINK TO DEMO VIDEO
https://youtu.be/BUF5eP8Flsk

"""
Standalone prediction script for unemployment rate prediction.
Loads the trained model and scaler, then predicts for a sample developing country.
"""
import joblib
import numpy as np
import pandas as pd

# load saved model and scaler
model = joblib.load('best_model.pkl')
scaler = joblib.load('scaler.pkl')

# sample input — represents a typical developing country observation
sample = {
    'Year': 2012,
    'GDP_Per_Capita': 3200.0,
    'Literacy_Rate_Female': 70.0,
    'Literacy_Rate_Male': 82.0,
    'Literacy_Rate_Adult': 76.0,
    'Primary_Completion_Rate': 85.0,
    'Pupil_Teacher_Ratio_Primary': 30.0,
    'School_Enrollment_Primary': 102.0,
    'Primary_Teachers': 120000,
    'Lower_Secondary_Completion_Rate': 60.0,
    'Pupil_Teacher_Ratio_Secondary': 22.0,
    'School_Enrollment_Secondary': 55.0,
    'Secondary_Teachers': 80000,
    'School_Enrollment_Tertiary': 18.0,
    'Govt_Education_Spending_Govt_Pct': 16.0,
    'Govt_Education_Spending_GDP_Pct': 4.2,
    'Labor_Force_Advanced_Education': 12.0,
    'Labor_Force_Basic_Education': 50.0,
    'Labor_Force_Intermediate_Education': 25.0,
    'Labor_Force_Female_Pct': 38.0,
    'Labor_Force_Total': 12000000,
    'NEET_Rate': 22.0,
    'Population_15_64_Pct': 58.0,
    'Population_Total': 25000000,
    'Region_Encoded': 4,
}

# predict
sample_df = pd.DataFrame([sample])
sample_scaled = scaler.transform(sample_df)
prediction = model.predict(sample_scaled)

print(f"\n{'='*50}")
print(f"Unemployment Rate Prediction")
print(f"{'='*50}")
print(f"\nInput features:")
for key, value in sample.items():
    print(f"  {key}: {value}")
print(f"\nThe model predicts an unemployment rate of {prediction[0]:.2f}%")
print(f"for a developing country with these characteristics.")
print(f"{'='*50}")

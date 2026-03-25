from fastapi import FastAPI, UploadFile, File, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
import joblib
import numpy as np
import pandas as pd
from io import StringIO
import os

# set up the app
app = FastAPI(
    title="Unemployment Prediction API",
    description="Predicts unemployment rate for developing countries based on education and labor indicators",
    version="1.0.0"
)

# configure CORS — specific origins only, no wildcards
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:3000",
        "http://localhost:8080",
        "http://localhost:5000",
        "https://your-flutter-app-domain.com",
    ],
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE"],
    allow_headers=["Content-Type", "Authorization", "Accept"],
)

# load the trained model, scaler, and feature names
BASE_DIR = os.path.dirname(os.path.abspath(__file__))

model = joblib.load(os.path.join(BASE_DIR, "best_model.pkl"))
scaler = joblib.load(os.path.join(BASE_DIR, "scaler.pkl"))
feature_names = joblib.load(os.path.join(BASE_DIR, "feature_names.pkl"))


# input schema with validation for all 25 features
class UnemploymentInput(BaseModel):
    Year: int = Field(..., ge=1990, le=2030, description="Year of observation")
    GDP_Per_Capita: float = Field(..., ge=0, le=50000, description="GDP per capita in current US$")
    Literacy_Rate_Female: float = Field(..., ge=0, le=100, description="Female literacy rate (%)")
    Literacy_Rate_Male: float = Field(..., ge=0, le=100, description="Male literacy rate (%)")
    Literacy_Rate_Adult: float = Field(..., ge=0, le=100, description="Adult literacy rate (%)")
    Primary_Completion_Rate: float = Field(..., ge=0, le=200, description="Primary completion rate (%)")
    Pupil_Teacher_Ratio_Primary: float = Field(..., ge=1, le=100, description="Pupils per teacher, primary")
    School_Enrollment_Primary: float = Field(..., ge=0, le=200, description="Gross primary enrollment (%)")
    Primary_Teachers: float = Field(..., ge=0, le=5000000, description="Number of primary teachers")
    Lower_Secondary_Completion_Rate: float = Field(..., ge=0, le=200, description="Lower secondary completion rate (%)")
    Pupil_Teacher_Ratio_Secondary: float = Field(..., ge=1, le=100, description="Pupils per teacher, secondary")
    School_Enrollment_Secondary: float = Field(..., ge=0, le=200, description="Gross secondary enrollment (%)")
    Secondary_Teachers: float = Field(..., ge=0, le=5000000, description="Number of secondary teachers")
    School_Enrollment_Tertiary: float = Field(..., ge=0, le=200, description="Gross tertiary enrollment (%)")
    Govt_Education_Spending_Govt_Pct: float = Field(..., ge=0, le=50, description="Education spending as % of govt expenditure")
    Govt_Education_Spending_GDP_Pct: float = Field(..., ge=0, le=20, description="Education spending as % of GDP")
    Labor_Force_Advanced_Education: float = Field(..., ge=0, le=100, description="Labor force with advanced education (%)")
    Labor_Force_Basic_Education: float = Field(..., ge=0, le=100, description="Labor force with basic education (%)")
    Labor_Force_Intermediate_Education: float = Field(..., ge=0, le=100, description="Labor force with intermediate education (%)")
    Labor_Force_Female_Pct: float = Field(..., ge=0, le=100, description="Female share of labor force (%)")
    Labor_Force_Total: float = Field(..., ge=0, le=500000000, description="Total labor force")
    NEET_Rate: float = Field(..., ge=0, le=100, description="Youth not in education, employment, or training (%)")
    Population_15_64_Pct: float = Field(..., ge=0, le=100, description="Population ages 15-64 as % of total")
    Population_Total: float = Field(..., ge=0, le=2000000000, description="Total population")
    Region_Encoded: int = Field(..., ge=0, le=5, description="Region code: 0=East Asia, 1=Europe & Central Asia, 2=Latin America, 3=Middle East & North Africa, 4=South Asia, 5=Sub-Saharan Africa")


@app.get("/")
def root():
    """health check and basic info about the API"""
    return {
        "message": "Unemployment Prediction API for Developing Countries",
        "usage": "POST to /predict with required features",
        "docs": "/docs for Swagger UI"
    }


@app.post("/predict")
def predict(input_data: UnemploymentInput):
    """predict unemployment rate from the 25 input features"""
    # convert input to dataframe with the right column order
    input_dict = input_data.model_dump()
    input_df = pd.DataFrame([input_dict])[feature_names]

    # scale the features and run prediction
    input_scaled = scaler.transform(input_df)
    prediction = model.predict(input_scaled)[0]

    return {
        "prediction": round(float(prediction), 2),
        "unit": "% of total labor force",
        "model": "Random Forest Regressor",
        "status": "success"
    }


@app.post("/retrain")
async def retrain(file: UploadFile = File(...)):
    """
    upload new CSV data to retrain the model.
    the CSV must have the same columns as the training data, including 'Unemployment_Rate'.
    """
    try:
        # read the uploaded CSV
        contents = await file.read()
        new_data = pd.read_csv(StringIO(contents.decode("utf-8")))

        # check that all required columns are present
        required_cols = list(feature_names) + ["Unemployment_Rate"]
        missing_cols = [col for col in required_cols if col not in new_data.columns]
        if missing_cols:
            raise HTTPException(
                status_code=400,
                detail=f"Missing columns in uploaded data: {missing_cols}"
            )

        # load existing training data and combine with the new data
        existing_data = pd.read_csv(os.path.join(BASE_DIR, "cleaned_data.csv"))
        new_data_filtered = new_data[required_cols].dropna()
        combined_data = pd.concat([existing_data[required_cols], new_data_filtered], ignore_index=True)

        # split into features and target
        X_new = combined_data[feature_names]
        y_new = combined_data["Unemployment_Rate"]

        # retrain the model from scratch
        from sklearn.model_selection import train_test_split
        from sklearn.ensemble import RandomForestRegressor
        from sklearn.preprocessing import StandardScaler
        from sklearn.metrics import mean_squared_error, r2_score

        X_train, X_test, y_train, y_test = train_test_split(
            X_new, y_new, test_size=0.2, random_state=42
        )

        new_scaler = StandardScaler()
        X_train_scaled = new_scaler.fit_transform(X_train)
        X_test_scaled = new_scaler.transform(X_test)

        new_model = RandomForestRegressor(n_estimators=100, random_state=42)
        new_model.fit(X_train_scaled, y_train)

        # check how the retrained model performs
        y_pred = new_model.predict(X_test_scaled)
        mse = mean_squared_error(y_test, y_pred)
        r2 = r2_score(y_test, y_pred)

        # save the updated model and scaler
        joblib.dump(new_model, os.path.join(BASE_DIR, "best_model.pkl"))
        joblib.dump(new_scaler, os.path.join(BASE_DIR, "scaler.pkl"))

        # save the combined dataset for future retraining
        combined_data.to_csv(os.path.join(BASE_DIR, "cleaned_data.csv"), index=False)

        # update the in-memory references so predictions use the new model
        global model, scaler
        model = new_model
        scaler = new_scaler

        return {
            "status": "success",
            "message": "Model retrained successfully",
            "new_data_rows": len(new_data_filtered),
            "total_training_rows": len(combined_data),
            "metrics": {
                "test_mse": round(mse, 4),
                "test_r2": round(r2, 4)
            }
        }

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Retraining failed: {str(e)}")


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)

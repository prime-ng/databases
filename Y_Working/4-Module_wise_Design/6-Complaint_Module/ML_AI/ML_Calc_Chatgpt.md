# ML for Complaint Module table (cmp_ai_insights)

## Prompt Details: (ChatGPT - Project - Prime-AI/ML Model for Complaints)

## Final Architecture

```
Laravel (PHP)
   |
   | REST API (JSON)
   ↓
Python ML Microservice (FastAPI)
   |
   | ML Models
   ↓
Predictions
   |
   ↓
cmp_ai_insights table
```

**Prediction Targets**

| Field			        | Type		  | ML Task                     |
|-----------------------|-------------|-----------------------------|
|sentiment_score	    | -1 to +1	  | Regression                  |
|escalation_risk_score	| 0–100	      | Classification / Regression |
|predicted_category_id	| Category ID | Multi-class Classification  |
|safety_risk_score	    | 0–100	      | Classification / Regression |

**ML MODEL STRATEGY**

| Prediction			| Model Type
|-----------------------|-----------------------------
|Sentiment Score		| NLP Transformer (BERT)
|Escalation Risk		| XGBoost / Logistic Regression
|Safety Risk			| XGBoost
|Category Prediction	| Multi-Class Classifier

**PROJECT STRUCTURE**

```
ml_complaints/
├── app/
│   ├── models/
│   │   ├── SentimentModel.py
│   │   ├── EscalationModel.py
│   │   ├── SafetyModel.py
│   │   └── CategoryModel.py
│   ├── utils/
│   │   ├── data_loader.py
│   │   ├── feature_engineer.py
│   │   └── model_saver.py
│   └── main.py
├── data/
│   ├── processed/
│   └── raw/
├── models/
│   ├── sentiment_model.joblib
│   ├── escalation_model.joblib
│   ├── safety_model.joblib
│   └── category_model.joblib
├── requirements.txt
└── README.md
```

**requirements.txt**

```
fastapi
uvicorn
scikit-learn
xgboost
pandas
numpy
joblib
transformers
torch
```

Install:
pip install -r requirements.txt

**TRAINING CODE (train.py)**

```
import joblib
import pandas as pd
from sklearn.model_selection import train_test_split
from xgboost import XGBClassifier
from sklearn.linear_model import LogisticRegression

# Load historical complaint data
df = pd.read_csv("complaints_training_data.csv")

X = df[[
    "complaint_text_length",
    "previous_complaints_count",
    "user_role",      # encoded
    "priority",       # encoded
    "severity"        # encoded
]]

# TARGETS
y_escalation = df["escalation_risk"]
y_safety = df["safety_risk"]
y_category = df["category_id"]

# Train Escalation Model
escalation_model = XGBClassifier()
escalation_model.fit(X, y_escalation)

# Train Safety Model
safety_model = XGBClassifier()
safety_model.fit(X, y_safety)

# Train Category Model
category_model = XGBClassifier(objective="multi:softmax")
category_model.fit(X, y_category)

joblib.dump(escalation_model, "models/escalation.pkl")
joblib.dump(safety_model, "models/safety.pkl")
joblib.dump(category_model, "models/category.pkl")
```

**SENTIMENT MODEL (BERT)**

```
from transformers import pipeline

sentiment_pipeline = pipeline(
    "sentiment-analysis",
    model="nlptown/bert-base-multilingual-uncased-sentiment"
)

def get_sentiment(text):
    result = sentiment_pipeline(text)[0]
    score_map = {
        "1 star": -1.0,
        "2 stars": -0.5,
        "3 stars": 0.0,
        "4 stars": 0.5,
        "5 stars": 1.0
    }
    return score_map[result["label"]]
```

**PREDICTION LOGIC (predict.py)**

```
import joblib
import numpy as np
from sentiment import get_sentiment

escalation_model = joblib.load("models/escalation.pkl")
safety_model = joblib.load("models/safety.pkl")
category_model = joblib.load("models/category.pkl")

def predict_all(data):
    X = np.array([[
        len(data["complaint_text"]),
        data["previous_complaints"],
        data["user_role"],
        data["priority"],
        data["severity"]
    ]])

    sentiment = get_sentiment(data["complaint_text"])

    escalation = escalation_model.predict_proba(X)[0][1] * 100
    safety = safety_model.predict_proba(X)[0][1] * 100
    category = int(category_model.predict(X)[0])

    return {
        "sentiment_score": sentiment,
        "escalation_risk_score": round(escalation, 2),
        "safety_risk_score": round(safety, 2),
        "predicted_category_id": category
    }
```

**by Inline AI**

```
from joblib import load
from transformers import pipeline

escalation_model = load("models/escalation.pkl")
safety_model = load("models/safety.pkl")
category_model = load("models/category.pkl")
sentiment_pipeline = pipeline(
    "sentiment-analysis",
    model="nlptown/bert-base-multilingual-uncased-sentiment"
)

def predict_complaint(complaint):
    # Sentiment
    sentiment = get_sentiment(complaint)
    
    # Escalation
    escalation = escalation_model.predict([[len(complaint), 0, 0, 0, 0]])[0]
    
    # Safety
    safety = safety_model.predict([[len(complaint), 0, 0, 0, 0]])[0]
    
    # Category
    category = category_model.predict([[len(complaint), 0, 0, 0, 0]])[0]
    
    return {
        "sentiment": sentiment,
        "escalation": escalation,
        "safety": safety,
        "category": category
    }
```

**FASTAPI SERVER (app.py)**

```
from fastapi import FastAPI
from predict import predict_all

app = FastAPI()

@app.post("/predict")
def predict(payload: dict):
    return predict_all(payload)
```

**by Inline AI**
```
from fastapi import FastAPI
from predict import predict_all

app = FastAPI()

@app.post("/predict")
async def predict_complaint(complaint: str):
    result = predict_all({"complaint_text": complaint})
    return result
```

Run:
uvicorn app:app --host 0.0.0.0 --port 8000

**LARAVEL INTEGRATION (VERY IMPORTANT)**
Laravel Service Class

```
namespace App\Services;

use Illuminate\Support\Facades\Http;

class AiInsightService
{
    public function analyzeComplaint(array $data)
    {
        $response = Http::post('http://127.0.0.1:8000/predict', $data);
        return $response->json();
    }
}

```

**Laravel Controller Usage**

```
$ai = app(\App\Services\AiInsightService::class);

$result = $ai->analyzeComplaint([
    'complaint_text' => $complaint->description,
    'previous_complaints' => $user->complaints()->count(),
    'user_role' => $user->role_id,
    'priority' => $complaint->priority_id,
    'severity' => $complaint->severity_id,
]);

DB::table('cmp_ai_insights')->updateOrInsert(
    ['complaint_id' => $complaint->id],
    [
        'sentiment_score' => $result['sentiment_score'],
        'escalation_risk_score' => $result['escalation_risk_score'],
        'safety_risk_score' => $result['safety_risk_score'],
        'predicted_category_id' => $result['predicted_category_id'],
        'model_version' => 'v1.0'
    ]
);
```


**by Inline AI**

```
namespace App\Http\Controllers;

use App\Services\AiInsightService;

class ComplaintController extends Controller
{
    public function analyzeComplaint(Request $request)
    {
        $service = new AiInsightService();
        $result = $service->analyzeComplaint($request->all());
        return response()->json($result);
    }
}
```

🛡️ PRODUCTION BEST PRACTICES

✅ Queue AI calls (Laravel Queue)
✅ Cache predictions
✅ Model versioning (already supported)
✅ Retrain monthly
✅ Feature store table (recommended)

📌 WHAT YOU HAVE NOW

✔ Real ML (not fake rules)
✔ Fully scalable
✔ ERP-ready
✔ Works with PHP
✔ AI-future proof


# ML for Complaint Module table (cmp_ai_insights)


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

| Field			         | Type		  | ML Task                     |
|-----------------------|-------------|-----------------------------|
|sentiment_score	      | -1 to +1	  | Regression                  |
|escalation_risk_score	| 0–100	     | Classification / Regression |
|predicted_category_id	| Category ID | Multi-class Classification  |
|safety_risk_score	   | 0–100	     | Classification / Regression |

sentiment_score, escalation_risk_score,safety_risk_score, predicted_category_id

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


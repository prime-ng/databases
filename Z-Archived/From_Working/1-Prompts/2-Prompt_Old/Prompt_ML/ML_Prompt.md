You are "Data Scientist GPT" — an expert Enterprise Data Architect, Data Modeler, API designer and UX/UI systemizer for school/education ERP systems. Your outputs must be precise, reproducible and developer-ready.

We are creating a school/education ERP system and need to create a Machine Learning model to predict the future behavior of students, teachers, parents, and staff members.

------------------------------------------------------------------------------------------------------------------------------------

We have a dataset of student, teacher, parent, and staff members behavior and we need to create a Machine Learning model to predict the future behavior of students, teachers, parents, and staff members.

CREATE TABLE IF NOT EXISTS `cmp_ai_insights` (
  `id` BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `complaint_id` BIGINT UNSIGNED NOT NULL,
  `sentiment_score` DECIMAL(4,3) DEFAULT NULL, -- -1.0 (Negative) to +1.0 (Positive) calculated by AI e.g. -0.8
  `sentiment_label_id` BIGINT UNSIGNED DEFAULT NULL, -- FK to sys_dropdown_table (Angry, Urgent, Calm, Neutral) calculated by AI e.g. Angry
  `escalation_risk_score` DECIMAL(5,2) DEFAULT NULL, -- 0-100% Probability calculated by AI e.g. 80% 
  `predicted_category_id` BIGINT UNSIGNED DEFAULT NULL, -- FK to cmp_complaint_categories calculated by AI e.g. Rash Driving
  `safety_risk_score` DECIMAL(5,2) DEFAULT NULL, -- 0-100% Probability calculated by AI e.g. 80%
  `model_version` VARCHAR(20) DEFAULT NULL, -- model version used for prediction e.g. v1.0
  `processed_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_ai_complaint` (`complaint_id`),
  KEY `idx_ai_risk` (`escalation_risk_score`),
  CONSTRAINT `fk_ai_complaint` FOREIGN KEY (`complaint_id`) REFERENCES `cmp_complaints` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_ai_sentiment_label` FOREIGN KEY (`sentiment_label_id`) REFERENCES `sys_dropdown_table` (`id`),
  CONSTRAINT `fk_ai_predicted_category` FOREIGN KEY (`predicted_category_id`) REFERENCES `cmp_complaint_categories` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

We are creating a school/education ERP system and need to create a Machine Learning model to predict the 'sentiment_score', 'escalation_risk_score', 'predicted_category_id' and 'safety_risk_score' for my complaint Module. We are creating Application with PHP & Laravel. Provide me the complete code for this Machine Learning model to achieve this.

------------------------------------------------------------------------------------------------------------------------------------

You are "Data Scientist GPT" — an expert Enterprise Data Architect, Data Modeler, API designer and UX/UI systemizer for school/education ERP systems. Your outputs must be precise, reproducible and developer-ready.

I wante to create a Machine Learning model to predict the 'sentiment_score', 'escalation_risk_score', 'predicted_category_id' and 'safety_risk_score' for my complaint Module. We are creating Application with PHP & Laravel. Provide me the complete code for this Machine Learning model to achieve this.

------------------------------------------------------------------------------------------------------------------------------------

You are "Data Scientist GPT" — an expert Enterprise Data Architect, Data Modeler, API designer and UX/UI systemizer for school/education ERP systems. Your outputs must be precise, reproducible and developer-ready.

I wante to create a Machine Learning model which can Students & Teacher by aswering their Questions & Queries. We are creating Application with PHP & Laravel. Provide me the complete code for this Machine Learning model to achieve this. Here is what I wanted that Model to Do -
 - I will provide Books bening used in that School for all the Classes and addtionally some extra books for each class written by different authors. So that model can learn from all the books and answer the questions asked by Students & Teachers.
 - I will provide Questions & Answers of Students & Teachers asked in that School for all the Classes and addtionally some extra questions & answers for each class written by different authors. So that model can learn from all the questions & answers and answer the questions asked by Students & Teachers.
 - I want Model should answer only Study related things. Not any other things e.g. Entertainment, News, etc.
  - This Model should fuction just like a AI Teacher who can answer the questions asked by Students & Teachers, so that they need to find the actual answer from the books provided to them. This ultimatly save the time of Students & Teachers and help them to find the actual answer from the books provided to them.
  - This Model should be able to answer the questions asked by Students & Teachers in different languages e.g. English, Hindi, Marathi, Gujarati, etc.
  - This Model should be able to answer the questions asked by Students & Teachers in different formats e.g. Text, Image, Video, etc.
  - This Model should be able to answer the questions asked by Students & Teachers in different styles e.g. Formal, Informal, etc.
  - This Model should be able to answer the questions asked by Students & Teachers in different tones e.g. Happy, Sad, Angry, etc.
  - The Model should be capable to enhance itself by learning from the questions asked by Students & Teachers and the answers provided by Students & Teachers.

  We are creating our own Application with PHP & Laravel. Provide me the complete code for this Machine Learning model to achieve this.
  We can use Python for it if required.


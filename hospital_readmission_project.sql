CREATE DATABASE ascend_quick_project;
USE ascend_quick_project;

# Project: Hospital Readmission Analysis
# Dataset: 8,000 patients, 17 variables
# Objective: identify key drivers of readmission to support clinical and operational decision making
# Author: Tesneem Fnais
# Date: 10-11 April 2026

## NOTE: this is a synthetic dataset 
# Data Source: Kaggle (Hospital Patient Readmission Dataset) 
# https://www.kaggle.com/datasets/mohamedasak/hospital-patient-readmission-dataset
----------------------------------------

# overview of the dataset
SELECT *
FROM hospital_data
LIMIT 50;

DESCRIBE hospital_data;

SELECT COUNT(*)
FROM hospital_data;

----------------------------------------
# EDA

# total patients
SELECT
COUNT(*) AS patient_count
FROM hospital_data;

# Gender Distribution
SELECT
gender,
COUNT(*) AS patient_count,
ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS percentage
FROM hospital_data
GROUP BY gender;

# age distribution 
SELECT
MIN(age) AS min_age,
ROUND(AVG(age), 0) AS avg_age,
MAX(age) AS max_age
FROM hospital_data;

SELECT
age_group,
COUNT(*) AS patient_count,
ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS percentage
FROM (SELECT
CASE 
WHEN age BETWEEN 18 AND 30 THEN '18-30'
WHEN age BETWEEN 31 AND 43 THEN '31-43'
WHEN age BETWEEN 44 AND 56 THEN '44-56'
WHEN age BETWEEN 57 AND 69 THEN '57-69'
WHEN age BETWEEN 70 AND 82 THEN '70-82'
WHEN age BETWEEN 83 AND 95 THEN '83-95'
END AS age_group 
FROM hospital_data) AS sub
GROUP BY age_group
ORDER BY age_group;

# types of diagnosis
SELECT
DISTINCT primary_diagnosis
FROM hospital_data
ORDER BY primary_diagnosis;

# Distribution of Primary Diagnosis
SELECT
primary_diagnosis,
COUNT(*) AS patient_count,
ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 2) AS percentage
FROM hospital_data
GROUP BY primary_diagnosis
ORDER BY patient_count DESC;

----------------------------------------
# Scale of the Problem (Readmission Rate)

# Overall Readmission Rate 
SELECT
COUNT(*) AS total,
SUM(CASE WHEN label = 1 THEN 1 ELSE 0 END) AS readmission_count, 
ROUND(SUM(CASE WHEN label = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS readmission_rate_pct
FROM hospital_data;

#  readmission rate by primary diagnosis
SELECT 
primary_diagnosis,
COUNT(*) AS total_patients,
SUM(CASE WHEN label =1 THEN 1 ELSE 0 END) AS  readmitted_patients,
ROUND(SUM(CASE WHEN label =1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS pct_of_primary_diagnosis_readmission
FROM hospital_data
GROUP BY primary_diagnosis
ORDER BY pct_of_primary_diagnosis_readmission DESC;

# Readmission Rate by Age Group
SELECT
CASE 
WHEN age BETWEEN 18 AND 30 THEN '18-30'
WHEN age BETWEEN 31 AND 43 THEN '31-43'
WHEN age BETWEEN 44 AND 56 THEN '44-56'
WHEN age BETWEEN 57 AND 69 THEN '57-69'
WHEN age BETWEEN 70 AND 82 THEN '70-82'
WHEN age BETWEEN 83 AND 95 THEN '83-95'
END AS age_group,
COUNT(*) AS patient_count,
SUM(CASE WHEN label=1 THEN 1 ELSE 0 END) AS readmitted_patients,
ROUND(SUM(CASE WHEN label=1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS pct_of_age_group_readmission
FROM hospital_data
GROUP BY age_group
ORDER BY age_group;

# Readmission Rate by Comorbidities 
SELECT 
comorbidities_count,
COUNT(*) AS patient_count,
SUM(CASE WHEN label=1 THEN 1 ELSE 0 END) AS comorbidities_readmission,
ROUND(SUM(CASE WHEN label=1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS pct_comorbidities_readmission
FROM hospital_data
GROUP BY comorbidities_count
ORDER BY comorbidities_count;

# Readmission Rate by Discharge Disposition 
SELECT
discharge_disposition,
COUNT(*) AS patient_count,
SUM(CASE WHEN label=1 THEN 1 ELSE 0 END) AS patient_readmission,
ROUND(SUM(CASE WHEN label=1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS pct_discharge_disposition
FROM hospital_data
GROUP BY discharge_disposition
ORDER BY pct_discharge_disposition DESC;

----------------------------------------
# Operational Analysis

# Avarage LOS Based on Diagnosis and Treatment
SELECT
primary_diagnosis,
treatment_type,
ROUND(AVG(length_of_stay),1) AS avg_los
FROM hospital_data
GROUP BY primary_diagnosis, treatment_type
ORDER BY avg_los DESC;


# are uninsured patients undersereved? (features such as no-show rates, mortality, and refusing care can further support the analysis)
SELECT
insurance_type,
COUNT(*) AS patient_count,
SUM(CASE WHEN label=1 THEN 1 ELSE 0 END) AS readmitted_patients, 
ROUND(SUM(CASE WHEN label=1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS pct_readmitted_patients,
ROUND(AVG(followup_visits_last_year), 2) AS avg_followup_visit
FROM hospital_data
GROUP BY insurance_type
ORDER BY pct_readmitted_patients DESC;

# validating medicare's high readmission rate, is it age driven? (result = avg age is 76 for medicare, higher than other insurances)
SELECT
insurance_type,
COUNT(*) AS patient_count,
MIN(age) AS min_age,
ROUND(AVG(age), 0) AS avg_age,
MAX(age) AS max_age
FROM hospital_data
WHERE age > 57 # corresponding to the predefined age group (57-69)
GROUP BY insurance_type
ORDER BY patient_count DESC;

# Which season has the highest readmission rate
SELECT
season,
COUNT(*) AS total_patients,
SUM(CASE WHEN label=1 THEN 1 ELSE 0 END) AS readmitted_patients,
ROUND(SUM(CASE WHEN label=1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS pct_readmitted_patients
FROM hospital_data
GROUP BY season
ORDER BY pct_readmitted_patients DESC;

----------------------------------------

# further operational analysis 

# avarage LOS for each patient based on diagnosis (similar to previous query "# Avarage LOS Based on Diagnosis and Treatment Type")
# the purpose of this query is to showcase analysis skills
SELECT
patient_id, 
primary_diagnosis,
length_of_stay,
ROUND(AVG(length_of_stay) OVER(PARTITION BY primary_diagnosis),2) AS avg_los_per_diagnosis
FROM hospital_data
ORDER BY avg_los_per_diagnosis DESC;

# top high readmission risk patients by diagnosis (Ranking)
SELECT
patient_id,
primary_diagnosis,
readmission_risk_score,
DENSE_RANK() OVER( 
PARTITION BY primary_diagnosis
ORDER BY readmission_risk_score DESC) AS risk_rank
FROM hospital_data;

----------------------------------------

# Running Total of Admissions per month
SELECT
DATE_FORMAT(str_to_date(admission_date, '%m/%d/%Y'), '%Y-%m') AS admission_month,
COUNT(*) AS monthly_admissions,
SUM(COUNT(*)) OVER(ORDER BY DATE_FORMAT(str_to_date(admission_date, '%m/%d/%Y'), '%Y-%m')) AS cumulative_admissions
FROM hospital_data
group by admission_month
ORDER BY admission_month;

# Ranking Diagnosis by Readmission Risk per Region
WITH readmission_region_diagnosis AS ( 
SELECT
region,
primary_diagnosis,
#COUNT(*) AS total_patients, # no need, might cause confusion 
ROUND(SUM(CASE WHEN label=1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS readmission_rate
FROM hospital_data
GROUP BY region, primary_diagnosis),

ranked AS (SELECT *,
RANK() OVER(PARTITION BY region ORDER BY readmission_rate DESC) AS top_diagnosis
FROM readmission_region_diagnosis)
SELECT *
FROM ranked
WHERE top_diagnosis=1
ORDER BY readmission_rate DESC;

# Define High Risk patient profiles(readmission rate more than 80%)
SELECT 
MIN(readmission_risk_score), 
MAX(readmission_risk_score)
FROM hospital_data; 

SELECT 
COUNT(*) AS total_patients,
ROUND(AVG(readmission_risk_score), 2) AS avg
FROM hospital_data
WHERE readmission_risk_score > 0.8;

WITH high_risk AS (SELECT *
FROM hospital_data
WHERE readmission_risk_score > 0.8) 

SELECT
primary_diagnosis,
COUNT(*) AS high_risk_patients,
ROUND(AVG(age),0) AS avg_age,
ROUND(AVG(comorbidities_count),1) AS avg_comorbidities,
ROUND(AVG(length_of_stay),1) AS avg_los,
ROUND(SUM(CASE WHEN label=1 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS readmission_rate
FROM high_risk
GROUP BY primary_diagnosis
ORDER BY high_risk_patients DESC;


# patients above avrage readmission risk score per diagnosis group
# original approach (replaced with CTE for computational performance)
/*SELECT
patient_id,
primary_diagnosis,
readmission_risk_score,
ROUND((SELECT AVG(readmission_risk_score)
FROM hospital_data h2
WHERE h2.primary_diagnosis=h1.primary_diagnosis), 2) AS avg_for_diagnosis
FROM hospital_data h1
WHERE readmission_risk_score > ( SELECT AVG(readmission_risk_score) 
FROM hospital_data h2
WHERE h2.primary_diagnosis=h1.primary_diagnosis)
ORDER BY primary_diagnosis, readmission_risk_score DESC;*/

WITH diagnosis_avg AS (SELECT
primary_diagnosis,
ROUND(AVG(readmission_risk_score), 2) AS avg_risk
FROM hospital_data
GROUP BY primary_diagnosis)
SELECT 
h.patient_id,
h.primary_diagnosis,
h.readmission_risk_score,
d.avg_risk AS avg_for_diagnosis
FROM hospital_data h
JOIN diagnosis_avg d ON h.primary_diagnosis = d.primary_diagnosis
WHERE h.readmission_risk_score > d.avg_risk
ORDER BY h.primary_diagnosis, h.readmission_risk_score DESC;

----------------------------------------

# END OF PROJECT :)

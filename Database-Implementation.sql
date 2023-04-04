-- Q0. You can find our schema in leeant22.

-- Q1.
CREATE TABLE provider (
	provider_id VARCHAR(2) PRIMARY KEY,
	name VARCHAR(100),
	phone VARCHAR(10),
	email VARCHAR(200)
);

CREATE TABLE InsurancePlan (
	plan_id VARCHAR(3) PRIMARY KEY,
	name VARCHAR(50),
	coverage_percentage INT CHECK (coverage_percentage >= 0),
	remaining_percentage INT CHECK (remaining_percentage >= 0)
);

CREATE TABLE policyholder (
	policyholder_id VARCHAR(8) PRIMARY KEY,
	income VARCHAR(15)  CHECK (income IN ('<20,000', '20,000-50,000', '50,000-100,000', '>100,000')),
	first_name VARCHAR(100),
	last_name VARCHAR(100),
	phone VARCHAR(10),
	email VARCHAR(200),
	address VARCHAR(200)
);

CREATE TABLE patient (
	patient_id VARCHAR(8) PRIMARY KEY,
	first_name VARCHAR(100),
	last_name VARCHAR(100),
	bmi FLOAT CHECK (bmi >= 0),
	race VARCHAR(50) CHECK( race IN('White', 'Asian', 'Black', 'Hispanic', 'Native American', 'Pacific Islander')),
	age_range VARCHAR(15) CHECK (age_range IN ('Under 18', '18-24', '25-34', '35-44', '45-54', '55-64', 'Over 65')),
	ssn INT,
	sex VARCHAR(50),
	policyholder_id VARCHAR(8) REFERENCES policyholder(policyholder_id),
	state  VARCHAR(50), 
	city VARCHAR(100)
);

CREATE TABLE claim (
	claim_id SERIAL PRIMARY KEY,
	patient_id VARCHAR(8) REFERENCES patient(patient_id),
	policyholder_id VARCHAR(8) REFERENCES policyholder(policyholder_id),
	provider_id VARCHAR(2)  REFERENCES provider(provider_id),
	date_of_service DATE,
	total_amount FLOAT CHECK (total_amount >= 0),
	status VARCHAR(50) CHECK (status IN('Complete', 'Incomplete'))
);

CREATE TABLE payment (
	payment_number INT,
	claim_id INT REFERENCES claim(claim_id), 
	date_of_payment DATE,
	amount FLOAT CHECK (amount >= 0),
	PRIMARY KEY(payment_number, claim_id)
);

CREATE TABLE InsuranceContracts (
	policyholder_id VARCHAR(8) REFERENCES policyholder(policyholder_id),
	plan_id VARCHAR(3) REFERENCES InsurancePlan(plan_id),
	PRIMARY KEY(policyholder_id, plan_id)
);

-- Q2.
-- 1. What type of insurance plan does a policyholder have? (Policyholder)
SELECT policyholder_id, ARRAY_AGG(plan_id)
FROM insurancecontracts
GROUP BY policyholder_id;

-- 2. Do males account for more claims than females? (Insurance)
SELECT sex, COUNT(claim_id) AS number_of_claims
FROM patient, claim
WHERE patient.patient_id = claim.patient_id
GROUP BY sex;

-- 3. What is the status of the claim for each patient? (Provider, Policyholder, Insurance)
SELECT patient_id, claim_id, status
FROM claim
GROUP BY patient_id, claim_id;

-- 4. What is the total number of claims associated with a policyholder? (Insurance, Policyholder)
SELECT policyholder_id, COUNT(*) AS number_of_claims
FROM claim
GROUP BY policyholder_id
ORDER BY COUNT(*) DESC;

-- 5. Do people living in certain regions account for more claims? (Insurance)
SELECT state, COUNT(*) AS number_of_claims
FROM claim c, patient p
WHERE c.patient_id = p.patient_id
GROUP BY state
ORDER BY COUNT(*) DESC;

-- 6. Which insurance plan is bought by the most policyholders? (Insurance, policyholders)
Select a.plan_id, a.name, count(b.policyholder_id) AS num_of_policyholders
From insuranceplan a, insurancecontracts b
Where a.plan_id = b.plan_id
Group by a.plan_id, a.name
Order by num_of_policyholders DESC;

-- 7. What is the total amount that each provider has submitted each year? (Provider, Insurance)
Select a.provider_id, a.name, date_part('year', b.date_of_service) AS year, sum(b.total_amount) AS total_amount_of_claim
From provider a, claim b
Where a.provider_id = b.provider_id
Group by a.provider_id, a.name, date_part('year', b.date_of_service)
Order by provider_id;

-- 8. How does income levels of policy holders affect the choice of insurance plan? (Policyholder, Insurance)
Select b.income, a.plan_id, c.name, c.coverage_percentage, count(a.policyholder_id) AS num_of_policyholders
From insurancecontracts a, policyholder b, insuranceplan c
Where a.policyholder_id = b.policyholder_id AND a.plan_id = c.plan_id 
Group by b.income, a.plan_id, c.name, c.coverage_percentage
Order by income, num_of_policyholders DESC;

-- 9. What sex has the highest percentage of patients? (Insurance)
With aa as (Select a.sex, count(a.patient_id) AS num_patients_by_sex
       From patient a
       Group by a.sex),
	 bb as (Select count(a.patient_id) AS num_patients
		From patient a)
Select aa.sex, Round(1.0 * num_patients_by_sex/num_patients * 100, 2) AS percentage_of_patients
From aa, bb
Order by percentage_of_patients DESC;

-- 10. What is the average claim amount per race? (Insurance)
Select aa.race, avg(aa.average_amount_per_patient) AS average_amount_per_race
From (Select a.patient_id, a.race, avg(b.total_amount) AS average_amount_per_patient
      From patient a, claim b
      Where a.patient_id = b.patient_id
      Group by a.patient_id, a.race) aa
Group by aa.race;

-- Q3.
-- 1. (Daphne's) Do males account for more claims than females? (Insurance)
SELECT sex, COUNT(claim_id)
FROM patient, claim
WHERE patient.patient_id = claim.patient_id
GROUP BY sex;

-- "Male"	14
-- "Female"	11

-- 2. (Anthony's) Do people living in certain regions account for more claims? (Insurance)
SELECT state, COUNT(*)
FROM claim c, patient p
WHERE c.patient_id = p.patient_id
GROUP BY state
ORDER BY COUNT(*) DESC;

-- "Idaho"	5
-- "New York"	3
-- "Washington"	3
-- "Florida"	2
-- "North Dakota"	2
-- "Colorado"	2
-- "Montana"	2
-- "Utah"	2
-- "Illinois"	1
-- "Oklahoma"	1
-- "Oregon"	1
-- "Texas"	1

-- 3. (An's) What is the age range with the highest percentage of patients? (Insurance)
With aa as (Select a.age_range, count(a.patient_id) AS num_patients_by_age
       		From patient a
       		Group by a.age_range),
     bb as (Select count(a.patient_id) AS num_patients
        	From patient a)
Select aa.age_range, Round(1.0 * num_patients_by_age/num_patients * 100, 2) AS percentage_of_patients
From aa, bb
Order by percentage_of_patients DESC;

-- "Under 18"	48.57
-- "55-64"	11.43
-- "45-54"	8.57
-- "35-44"	8.57
-- "25-34"	8.57
-- "Over 65"	8.57
-- "18-24"	5.71

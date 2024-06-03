SELECT * FROM `zubaer-dataset-project.Hospital_data.Hospital` limit 5;

# Number of records
SELECT count(*) FROM `zubaer-dataset-project.Hospital_data.Hospital`; -- Total 101766 records

# temporary table
create TEMP Table temp_table (
  encounter_id INTEGER, 
  patient_nbr INTEGER, 
  race STRING, 
  gender STRING, 
  age STRING, weight STRING, 
  admission_type_id INTEGER, 
  discharge_disposition_id INTEGER, 
  a1cresult STRING, 
  readmitted STRING
);

select * from temp_table;

# Profile analysis

select 
  encounter_id, 
  patient_nbr, 
  race, 
  gender, 
  age, 
  weight, 
  admission_type_id, 
  discharge_disposition_id, 
  a1cresult, 
  readmitted
from `zubaer-dataset-project.Hospital_data.Hospital`;

# Distinct counts for each attributes

WITH Distinct_Counts AS (
  SELECT 
    COUNT(DISTINCT encounter_id) AS encounter_id, 
    COUNT(DISTINCT patient_nbr) AS patient_nbr, 
    COUNT(DISTINCT race) AS race, 
    COUNT(DISTINCT gender) AS gender, 
    COUNT(DISTINCT age) AS age, 
    COUNT(DISTINCT weight) AS weight, 
    COUNT(DISTINCT admission_type_id) AS admission_type_id, 
    COUNT(DISTINCT discharge_disposition_id) AS discharge_disposition_id, 
    COUNT(DISTINCT a1cresult) AS a1cresult, 
    COUNT(DISTINCT readmitted) AS readmitted
  FROM `zubaer-dataset-project.Hospital_data.Hospital`
)

SELECT Attributes, Distinct_Counts
FROM Distinct_Counts
UNPIVOT (
  Distinct_Counts FOR Attributes IN (encounter_id, patient_nbr, race, gender, age, weight, 
                            admission_type_id, discharge_disposition_id, a1cresult, readmitted)
);


# unique patients

select 
encounter_id,
count(patient_nbr) as unique_patient,  
from `zubaer-dataset-project.Hospital_data.Hospital`
group by encounter_id;

# list of patient who have appeared more than 5 times

select 
patient_nbr,
count(patient_nbr) as unique_patient,  
from `zubaer-dataset-project.Hospital_data.Hospital`
group by patient_nbr
having count(patient_nbr) > 5;

# Count distinct patients

select 
count(distinct patient_nbr) as unique_patient,
from `zubaer-dataset-project.Hospital_data.Hospital`
;

# Summary table (part 1): Showing the counts and percentages of encounters by admission type

WITH AdmissionCounts AS (
  SELECT 
    CASE 
      WHEN admission_type_id = 1 THEN 'Emergency'
      WHEN admission_type_id = 2 THEN 'Urgent'
      WHEN admission_type_id = 3 THEN 'Elective'
      WHEN admission_type_id = 4 THEN 'Newborn'
      WHEN admission_type_id = 5 THEN 'Not_Available'
      WHEN admission_type_id = 6 THEN 'NULL (Missing)'
      WHEN admission_type_id = 7 THEN 'Trauma_Center'
      WHEN admission_type_id = 8 THEN 'Not_Mapped'
      ELSE 'Unknown'
    END AS Characteristic,
    COUNT(admission_type_id) AS N
  FROM `zubaer-dataset-project.Hospital_data.Hospital`
  GROUP BY Characteristic

),
AdjustedTotalCount AS (
  SELECT COUNT(admission_type_id) AS AdjustedTotal 
  FROM `zubaer-dataset-project.Hospital_data.Hospital`
  WHERE admission_type_id <> 6
),
FinalCounts AS (
  SELECT 
    AC.Characteristic,
    CASE
      WHEN AC.Characteristic = 'NULL (Missing)' THEN 
        CAST(AC.N AS STRING)
      ELSE 
        CONCAT(
          CAST(AC.N AS STRING), ' / ',                  
          CAST(ATC.AdjustedTotal AS STRING), 
          ' (',
          CASE 
            WHEN (AC.N > 0 AND ROUND(100 * (AC.N / ATC.AdjustedTotal), 1) > 0.1) THEN 
              CONCAT(ROUND(100 * (AC.N / ATC.AdjustedTotal), 1), '%')
            ELSE 
              '<0.1%'
          END,
          ')'
        )
    END AS Count_Percentage
  FROM AdmissionCounts AC
  CROSS JOIN AdjustedTotalCount ATC
)
SELECT * FROM FinalCounts
UNION ALL
SELECT 'Admission Type' AS Characteristic, '' AS Count_Percentage
ORDER BY 
  CASE 
    WHEN Characteristic = 'Admission Type' THEN 0
    WHEN Characteristic = 'Elective' THEN 1
    WHEN Characteristic = 'Emergency' THEN 2
    WHEN Characteristic = 'Newborn' THEN 3
    WHEN Characteristic = 'Not_Available' THEN 4
    WHEN Characteristic = 'Not_Mapped' THEN 5
    WHEN Characteristic = 'Trauma_Center' THEN 6
    WHEN Characteristic = 'Urgent' THEN 7
    ELSE 8
  END;

# Summary table (part 2): Do the admission types differ between genders when it comes to admission at the emergency department?

select 
  distinct(gender) -- 3 unique gender- 'Female', 'Male' and 'Unknown/Invalid'
FROM `zubaer-dataset-project.Hospital_data.Hospital`;

WITH AdmissionCounts AS (
  SELECT 
    CASE 
      WHEN admission_type_id = 1 THEN 'Emergency'
      WHEN admission_type_id = 2 THEN 'Urgent'
      WHEN admission_type_id = 3 THEN 'Elective'
      WHEN admission_type_id = 4 THEN 'Newborn'
      WHEN admission_type_id = 5 THEN 'Not_Available'
      WHEN admission_type_id = 6 THEN 'NULL (Missing)'
      WHEN admission_type_id = 7 THEN 'Trauma_Center'
      WHEN admission_type_id = 8 THEN 'Not_Mapped'
      ELSE 'Unknown'
    END AS Characteristic,
    COUNT(CASE WHEN gender = 'Male' THEN 1 ELSE NULL END) AS Male,
    COUNT(CASE WHEN gender = 'Female' THEN 1 ELSE NULL END) AS Female,
    COUNT(CASE WHEN gender = 'Unknown/Invalid' THEN 1 ELSE NULL END) AS Invalid
  FROM `zubaer-dataset-project.Hospital_data.Hospital`
  GROUP BY Characteristic
),
AdjustedTotalCount AS (
  SELECT 
  COUNT(case when admission_type_id <> 6 THEN 1 ELSE NULL END) AS AdjustedTotal,
  COUNT(case when admission_type_id = 6 and gender = 'Male' THEN 1 ELSE NULL END) AS missing_male,
  COUNT(case when admission_type_id = 6 and gender = 'Female' THEN 1 ELSE NULL END) AS missing_female,
  COUNT(case when admission_type_id = 6 and gender = 'Unknown/Invalid' THEN 1 ELSE NULL END) AS missing_invalid
  FROM `zubaer-dataset-project.Hospital_data.Hospital`
),

FinalCounts_Male AS (
  SELECT 
    AC.Characteristic,
    CASE
      WHEN AC.Characteristic = 'NULL (Missing)' THEN 
        CAST(ATC.missing_male AS STRING)
      ELSE 
        CONCAT(
          CAST(AC.Male AS STRING), ' / ',                  
          CAST(ATC.AdjustedTotal AS STRING), 
          ' (',
          CASE 
            WHEN (AC.Male > 0 AND ROUND(100 * (AC.Male / ATC.AdjustedTotal), 1) > 0.1) THEN 
              CONCAT(ROUND(100 * (AC.Male / ATC.AdjustedTotal), 1), '%')
            ELSE 
              '<0.1%'
          END,
          ')'
        )
    END AS Male
  FROM AdmissionCounts AC
  CROSS JOIN AdjustedTotalCount ATC
),
FinalCounts_Female AS (
  SELECT 
    AC.Characteristic,
    CASE
      WHEN AC.Characteristic = 'NULL (Missing)' THEN 
        CAST(ATC.missing_female AS STRING)
      ELSE 
        CONCAT(
          CAST(AC.Female AS STRING), ' / ',                  
          CAST(ATC.AdjustedTotal AS STRING), 
          ' (',
          CASE 
            WHEN (AC.Female > 0 AND ROUND(100 * (AC.Female / ATC.AdjustedTotal), 1) > 0.1) THEN 
              CONCAT(ROUND(100 * (AC.Female / ATC.AdjustedTotal), 1), '%')
            ELSE 
              '<0.1%'
          END,
          ')'
        )
    END AS Female
  FROM AdmissionCounts AC
  CROSS JOIN AdjustedTotalCount ATC
),
FinalCounts_Invalid AS (
  SELECT 
    AC.Characteristic,
    CASE
      WHEN AC.Characteristic = 'NULL (Missing)' THEN 
        CAST(ATC.missing_invalid AS STRING)
      ELSE 
        CONCAT(
          CAST(AC.Invalid AS STRING), ' / ',                  
          CAST(ATC.AdjustedTotal AS STRING), 
          ' (',
          CASE 
            WHEN AC.Invalid > 0  THEN 
               '<0.1%'
            ELSE 
              '0%'
          END,
          ')'
        )
    END AS Invalid
  FROM AdmissionCounts AC
  CROSS JOIN AdjustedTotalCount ATC
),
FinalCounts_Gender AS (
  SELECT 
    AC.Characteristic,
    FF.Female,
    FM.Male,
    FI.Invalid
  FROM AdmissionCounts AC
  JOIN FinalCounts_Female FF ON AC.Characteristic = FF.Characteristic
  JOIN FinalCounts_Male FM ON AC.Characteristic = FM.Characteristic
  JOIN FinalCounts_Invalid FI ON AC.Characteristic = FI.Characteristic
)
SELECT * FROM FinalCounts_Gender 
UNION ALL
SELECT 'Admission Type' AS Characteristic, '' AS Male,'' AS Female,'' AS Invalid
ORDER BY 
  CASE 
    WHEN Characteristic = 'Admission Type' THEN 0
    WHEN Characteristic = 'Elective' THEN 1
    WHEN Characteristic = 'Emergency' THEN 2
    WHEN Characteristic = 'Newborn' THEN 3
    WHEN Characteristic = 'Not_Available' THEN 4
    WHEN Characteristic = 'Not_Mapped' THEN 5
    WHEN Characteristic = 'Trauma_Center' THEN 6
    WHEN Characteristic = 'Urgent' THEN 7
    ELSE 8
  END;

# Summary table (part 3): Using the patients admitted through the emergency only, create a frequency table for encounter volume by age group.

select -- 10 unique group
  distinct(age) 
FROM `zubaer-dataset-project.Hospital_data.Hospital`;

select -- Emergency Total 7565
  count(admission_type_id) as emergency_total
FROM `zubaer-dataset-project.Hospital_data.Hospital`
where medical_specialty = 'Emergency/Trauma';

with em_age as -- 3rd summary table
(
select 
  age,
  count(admission_type_id) as N
FROM `zubaer-dataset-project.Hospital_data.Hospital`
where medical_specialty = 'Emergency/Trauma'
group by age
order by age
),

em_count as
( select
    count(admission_type_id) as em_total
FROM `zubaer-dataset-project.Hospital_data.Hospital`
where medical_specialty = 'Emergency/Trauma'
),

final_table as (
select 
age as Characteristic,
concat(
(cast (N as string)),
'(',
  CONCAT(ROUND(100 * (ea.N / ec.em_total), 1)),'%',
')'
) as N
from em_age as ea
cross join em_count as ec
order by age
)

select * from final_table
union all
select 'Age' as Characteristic, '' as N
order by Characteristic;

# Business Solution 1: Is there any association between admission type and blood glucose level (A1Cresult)?
-- Consider admission type 1, 2, 3 only
-- Exclude the cases where A1C result is not available or None

SELECT 
    CASE 
      WHEN admission_type_id = 1 THEN 'Emergency'
      WHEN admission_type_id = 2 THEN 'Urgent'
      WHEN admission_type_id = 3 THEN 'Elective'
    END AS Characteristic,
    COUNT(A1Cresult) AS N
  FROM `zubaer-dataset-project.Hospital_data.Hospital`
  where A1Cresult <> "None" and admission_type_id in (1,2,3)
  GROUP BY Characteristic;

#Main part
WITH PartA AS (
  SELECT 
    CASE 
      WHEN admission_type_id = 1 THEN 1
      WHEN admission_type_id = 2 THEN 2
      WHEN admission_type_id = 3 THEN 3
    END AS Characteristic,
    COUNT(CASE WHEN A1Cresult = ">7" OR A1Cresult = ">8" THEN 1 END) AS Diabetic,
    COUNT(CASE WHEN A1Cresult = "Norm" THEN 1 END) AS Normal
  FROM `zubaer-dataset-project.Hospital_data.Hospital`
  WHERE A1Cresult <> "None" AND admission_type_id IN (1, 2, 3)
  GROUP BY 1
  ORDER BY 1 ASC
),
Total_cal AS (
  SELECT
    COUNT(CASE WHEN A1Cresult = ">7" OR A1Cresult = ">8" THEN 1 END) AS Total_Diabetic,
    COUNT(CASE WHEN A1Cresult = "Norm" THEN 1 END) AS Total_Normal
  FROM `zubaer-dataset-project.Hospital_data.Hospital`
  WHERE A1Cresult <> "None" AND admission_type_id IN (1, 2, 3)
),
PartB AS (
  SELECT
    cast(a.Characteristic AS STRING) AS Characteristic,
    CONCAT(
      CAST(a.Diabetic AS STRING), " (", 
      ROUND(100 * (a.Diabetic / T.Total_Diabetic), 1), "%)"
    ) AS Diabetic,
    CONCAT(
      CAST(a.Normal AS STRING), " (", 
      ROUND(100 * (a.Normal / T.Total_Normal), 1), "%)"
    ) AS Normal
  FROM PartA AS a
  CROSS JOIN Total_cal AS T 
)

SELECT * FROM PartB
UNION ALL
SELECT 'admiss_type' AS Characteristic, ' ' AS Diabetic, ' ' AS Normal
ORDER BY 
  CASE 
    WHEN Characteristic = 'admiss_type' THEN 0
    WHEN Characteristic = '1' THEN 1
    WHEN Characteristic = '2' THEN 2
    WHEN Characteristic = '3' THEN 3
  END
;

#Business Question 2:Are there patients admitted through the emergency, having A1C results 8 or more who expired(died)?

WITH case1 AS (
  SELECT 
    age, 
    COUNT(CASE WHEN gender = 'Male' THEN 1 ELSE NULL END) AS Male,
    COUNT(CASE WHEN gender = 'Female' THEN 1 ELSE NULL END) AS Female
  FROM `zubaer-dataset-project.Hospital_data.Hospital`
  WHERE 
    admission_type_id = 1 AND 
    A1Cresult <> "None" AND 
    A1Cresult = ">8" AND
    discharge_disposition_id = 11
  GROUP BY age
  ORDER BY age ASC
),

total_count AS (
  SELECT 
    COUNT(CASE WHEN gender = 'Male' THEN 1 ELSE NULL END) AS total_male,
    COUNT(CASE WHEN gender = 'Female' THEN 1 ELSE NULL END) AS total_female
  FROM `zubaer-dataset-project.Hospital_data.Hospital`
  WHERE 
    admission_type_id = 1 AND 
    A1Cresult <> "None" AND 
    A1Cresult = ">8" AND
    discharge_disposition_id = 11
),

final AS (
  SELECT 
    c.age AS Characteristic,
    CONCAT(
      CAST(c.Male AS STRING), " (",
      ROUND(100 * (c.Male / t.total_male), 1), "%)"
    ) AS Male,
    CONCAT(
      CAST(c.Female AS STRING), " (",
      ROUND(100 * (c.Female / t.total_female), 1), "%)"
    ) AS Female
  FROM case1 AS c
  CROSS JOIN total_count AS t
)

SELECT * FROM final
UNION ALL
SELECT "Age Group" as Characteristic, " " as Male, "" as Female
ORDER BY Characteristic ASC;

#Business Question 3:Are there patients admitted through the emergency, having A1C results 8 or more who were readmitted within 30 days?

-- age, Gender(male, female) filter by emergency and A1C level >8 and readmitted <30
-- admission_type_id = 1 THEN 'Emergency'
-- A1Cresult = ">8"
-- A1Cresult <> "None"
-- readmitted = "<30"

WITH case1 AS (
  SELECT 
    age, 
    COUNT(CASE WHEN gender = 'Male' THEN 1 ELSE NULL END) AS Male,
    COUNT(CASE WHEN gender = 'Female' THEN 1 ELSE NULL END) AS Female
  FROM `zubaer-dataset-project.Hospital_data.Hospital`
  WHERE 
    admission_type_id = 1 AND 
    A1Cresult <> "None" AND 
    A1Cresult = ">8" AND
    readmitted = "<30"
  GROUP BY age
  ORDER BY age ASC
),

total_count AS (
  SELECT 
    COUNT(CASE WHEN gender = 'Male' THEN 1 ELSE NULL END) AS total_male,
    COUNT(CASE WHEN gender = 'Female' THEN 1 ELSE NULL END) AS total_female
  FROM `zubaer-dataset-project.Hospital_data.Hospital`
  WHERE 
    admission_type_id = 1 AND 
    A1Cresult <> "None" AND 
    A1Cresult = ">8" AND
    readmitted = "<30"
),

final AS (
  SELECT 
    c.age AS Characteristic,
    CONCAT(
      CAST(c.Male AS STRING), " (",
      ROUND(100 * (c.Male / t.total_male), 1), "%)"
    ) AS Male,
    CONCAT(
      CAST(c.Female AS STRING), " (",
      ROUND(100 * (c.Female / t.total_female), 1), "%)"
    ) AS Female
  FROM case1 AS c
  CROSS JOIN total_count AS t
)

SELECT * FROM final
UNION ALL
SELECT "Age Group" as Characteristic, " " as Male, "" as Female
ORDER BY Characteristic ASC;

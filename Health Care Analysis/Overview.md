# Hospital Data Analysis 
## Business Question Provided by Enayetur Raheem
The dataset represents ten years (1999-2008) of clinical care at 130 US hospitals and integrated delivery networks. It includes over 50 features representing patient and hospital outcomes. Information was extracted from the database for encounters that satisfied the following criteria.

(1)	It is an inpatient encounter (a hospital admission).<br>
(2)	It is a diabetic encounter, that is, one during which any kind of diabetes was entered into the system as a diagnosis.<br>
(3)	The length of stay was at least 1 day and at most 14 days.<br>
(4)	Laboratory tests were performed during the encounter.<br>
(5)	Medications were administered during the encounter.<br>

- What do the instances in this dataset represent?<br>
→ The instances represent hospitalized patient records diagnosed with diabetes.

- Are there recommended data splits?<br>
→ No recommendation. The standard train-test split could be used. Can use three-way holdout split (i.e., train-validation-test) when doing model selection.

- Does the dataset contain data that might be considered sensitive in any way?<br>
→ Yes. The dataset contains information about the age, gender, and race of the patients.

- Has Missing Values?<br>
→ Yes 

Dataset link: https://archive.ics.uci.edu/ml/datasets/diabetes+130-us+hospitals+for+years+1999-2008

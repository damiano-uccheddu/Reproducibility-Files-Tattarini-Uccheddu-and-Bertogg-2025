# Reproducibility Files – Tattarini, Uccheddu & Bertogg (2025)

**Reference:**
Tattarini, Giulia, Damiano Uccheddu, and Ariane Bertogg. *“Staying Sharp: Gendered Work–Family Life Courses and Later-Life Cognitive Functioning across Four European Welfare States.”* American Journal of Epidemiology, Oxford University Press, 29 August 2025, kwaf194. [https://doi.org/10.1093/aje/kwaf194](https://doi.org/10.1093/aje/kwaf194)

---

## Data availability

The Survey of Health, Ageing and Retirement in Europe (SHARE) data are distributed by SHARE-ERIC (Survey of Health, Ageing and Retirement in Europe – European Research Infrastructure Consortium) to registered users through the SHARE Research Data Center. The official SHARE Research Data Center website (https://releases.sharedataportal.eu/users/login) is the sole online access point to the SHARE data. Here SHARE users can download the SHARE data after a successful registration. For further details regarding SHARE microdata access, please visit http://www.share-project.org/data-access.html.

This paper uses data from SHARE Waves 1, 2, 3, 4, 5, 6, 7, 8 and 9 (DOIs: 10.6103/SHARE.w1.900, 10.6103/SHARE.w2.900, 10.6103/SHARE.w3.900, 10.6103/SHARE.w4.900, 10.6103/SHARE.w5.900, 10.6103/SHARE.w6.900, 10.6103/SHARE.w7.900, 10.6103/SHARE.w8.900, 10.6103/SHARE.w9.900), see Börsch-Supan et al. for methodological details. Additionally, this paper uses data from the generated Job Episodes Panel (DOI: 10.6103/SHARE.jep.900), see Brugiavini et al. for methodological details. The Job Episodes Panel release 9.0.0 is based on SHARE Waves 3 and 7 (DOIs: 10.6103/SHARE.w3.900, 10.6103/SHARE.w7.900).

The SHARE data collection has been funded by the European Commission, DG RTD through FP5 (QLK6-CT-2001-00360), FP6 (SHARE-I3: RII-CT-2006-062193, COMPARE: CIT5-CT-2005-028857, SHARELIFE: CIT4-CT-2006-028812), FP7 (SHARE-PREP: GA N°211 909, SHARE-LEAP: GA N°227 822, SHARE M4: GA N°261 982, DASISH: GA N°283 646) and Horizon 2020 (SHARE-DEV3: GA N°676 536, SHARE-COHESION: GA N°870 628, SERISS: GA N°654 221, SSHOC: GA N°823 782, SHARE-COVID19: GA N°101 015 924) and by DG Employment, Social Affairs & Inclusion through VS 2015/0195, VS 2016/0135, VS 2018/0285, VS 2019/0332, VS 2020/0313, SHARE-EUCOV: GA N°101 052 589 and EUCOVII: GA N°101 102 412. Additional funding from the German Federal Ministry of Education and Research (01UW1301, 01UW1801, 01UW2202), the Max Planck Society for the Advancement of Science, the U.S. National Institute on Aging (U01_AG09740-13S2, P01_AG005842, P01_AG08291, P30_AG12815, R21_AG025169, Y1-AG-4553-01, IAG_BSR06-11, OGHA_04-064, BSR12-04, R01_AG052527-02, R01_AG056329-02, R01_AG063944, HHSN271201300071C, RAG052527A) and from various national funding sources is gratefully acknowledged (see [www.share-eric.eu](https://www.share-eric.eu)).

---

## Folder Structure

```
<REPRODUCIBILITY_FOLDER>\
│
├── Code\
│   ├── 0. Master do-file\Master do-file.do
│   ├── 1. Dataset Creation\Dataset Creation.do
│   ├── 2.1. Data missingness fill (JEP)\Data missingness fill (JEP).do
│   ├── 2.2. Data Cleaning (General)\Data Cleaning (General).do
│   ├── 3. Data Cleaning (MCSQA)\Data Cleaning (MCSQA).do
│   ├── 4.1. Data Analysis (MCSQA)\Data Analysis (MCSQA).R
│   ├── 4.2. Data Analysis (Chronograms)\
│   │   ├── Data Analysis (Chronograms).do
│   │   └── Data Analysis (Chronograms) - By country.do
│   └── 4.3. Data Analysis (Main) - kwaf194\Data Analysis (Main).do
│
└── Stata schemes\
    ├── scheme-c_blind_family.scheme
    ├── scheme-c_blind_family_reversed.scheme
    ├── scheme-c_blind_employment.scheme
    └── scheme-c_blind_employment_reversed.scheme


<DATA_FOLDER>\
├── Source\
│   └── SHARE\
│       └── Release 9.0.0\
│           ├── sharew1_rel9-0-0_ALL_datasets_stata\
│           ├── sharew2_rel9-0-0_ALL_datasets_stata\
│           ├── sharew3_rel9-0-0_ALL_datasets_stata\
│           ├── sharew4_rel9-0-0_ALL_datasets_stata\
│           ├── sharew5_rel9-0-0_ALL_datasets_stata\
│           ├── sharew6_rel9-0-0_ALL_datasets_stata\
│           ├── sharew7_rel9-0-0_ALL_datasets_stata\
│           ├── sharew8_rel9-0-0_ALL_datasets_stata\
│           ├── sharew9_rel9-0-0_ALL_datasets_stata\
│           └── sharewX_rel9-0-0_gv_job_episodes_panel_stata\
│
└── Derived\
    └── COL_Tattarini_Uccheddu_Bertogg\
        ├── w1\
        ├── w2\
        ├── w3\
        ├── w4\
        ├── w5\
        ├── w6\
        ├── w7\
        ├── w8\
        ├── w9\
        ├── W_All\
        ├── JEP_imputed\
        └── Temp\

<OUTPUT_FOLDER>\
├── Common\
│   ├── Tables\
│   ├── Figures\
│   └── Log files\
│
└── kwaf194\
    ├── Tables\
    ├── Figures\
    └── Log files\
```

---

## Instructions

1. **Copy Stata schemes**
   Copy all `.scheme` files from `<BASE_FOLDER>/Stata schemes` to your Stata **ADO schemes folder** (e.g., `C:\ado\plus\`).

2. **Dataset input**
   Place the original SHARE datasets (waves 1–9 and job episodes panel) in `<DATA_FOLDER>/Source/SHARE/Release 9.0.0`.

3. **Adjust paths**
   Open `Master do-file.do` and update the global macros for:

   * `working_folder` → your `<BASE_FOLDER>/Code`
   * `output_folder` → your `<DATA_FOLDER>/Derived/COL_Tattarini_Uccheddu_Bertogg`
   * Other macros for input SHARE waves if your paths differ

4. **Run the analyses**
   From Stata:

   * Run `Master do-file.do` to execute the full replication sequence.
   * This will create datasets, impute missing values, clean data, and run the analyses.

5. **R scripts**

   * Run `Data Analysis (MCSQA).R` in R to reproduce sequence and cluster analyses.

6. **Outputs**

   * Tables and figures for the main paper will appear in `<OUTPUT_FOLDER>/kwaf194`
   * Other outputs (e.g., sequence analysis figures) will appear in `<OUTPUT_FOLDER>/Common`

---

## Notes

* All `.do` files are sequenced in the order of the Master do-file.
* Temporary datasets are saved in `<DATA_FOLDER>/Derived/Temp`.
* Logs will be created in the corresponding log folders.

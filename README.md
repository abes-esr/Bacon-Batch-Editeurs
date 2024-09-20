---
editor_options: 
  markdown: 
    wrap: sentence
---

# Set of bash scripts for importing KBart files

## Part 1 : Global description

### Origin of KBart files

#### By publishers' deposit : AbesBacon

Files are pushed by publishers to ABES's owncloud server.
The Traite_OwnCloud.sh script put them onto begonia server.

#### By recovery from publishers : Autre (others)

Files are fetch from publishers web site by a curl request.

### Processing Files

New files are compared to archived files ; if there are any differences an html diff file is generated to display them.
New files if different are stored in Archive directory.

At the end of the process, a summary file of the changed files is created.

That's the job of the CheckMajEditeur.sh script that finally sends a summary mail.

### some details

The tree of involved directories is :

```         
├── MajEditeurs_ahe
│   ├── Archive
│   │   ├── AbesBacon
│   │   │   ├── BNF_GLOBAL_GALLICA-ALLJOURNALS
│   │   │   ...
│   │   │   └── TI_Global_VieillissementPathologiesEtRehabilitationDuBatiment
│   │   ├── Autre
│   │   │   ├── 19th_Century_British_Pamphlets
│   │   │   ...
│   │   │   └── wiley_all_obooks_2022-07-01-1657648471610
│   │   ...
│   │   │
│   ├── bin
│   │   ├── checks
│   │   └── soundex
│   ├── conf
│   │   ├── CheckMajEditeurs_ahe
│   │   │   ├── AbesBacon
│   │   │   └── Autre
│   │   └── Traite_OwnCloud_ahe
│   │       └── AbesBacon
│   ├── DerniereVersion
│   │   ├── AbesBacon
│   │   └── Autre
│   ├── Doc
│   └── rundir
│       ├── CheckMajEditeurs_ahe
│       │   ├── AbesBacon
│       │   │   └── 2024-09-02_21:45:01
│       │   │       ├── 03
│       │   │       ├── 04
│       │   │       ├── 05
│       │   │       ├── 06
│       │   │       └── 07_Diff
│       │   └── Autre
│       │       └── 2024-09-02_23:00:02
│       │           ├── 03
│       │           ├── 04
│       │           ├── 05
│       │           ├── 06
│       │           └── 07_Diff
│       └── Traite_OwnCloud_ahe
│           └── AbesBacon
│               └── 2024-09-02_21:35:01
```
#### Conf directory 
Configuration files are stored in a **conf** directory.
#### Run directory 
Each script execution is logged into a **rundir** directory as **/rundir/**<program name>/<editor>/<running date> .
The process is divided into numbered steps and the data files are copied as many times as necessary; this is done for tracking or debugging purposes.
#### Log files 
Log files are under **rundir** directory : 99_log, 99_Mail, 99_Mail_Warning, 99_Mail_Warning_URL .
e.g. /home/devel/MajEditeurs_ahe/rundir/CheckMajEditeurs_ahe/Autre/2024-09-19_23:00:01/99_log

The file listing the URL REDIRECTs for a given run of the script is :
/home/devel/MajEditeurs_ahe/rundir/CheckMajEditeurs_ahe/Autre/2024-09-19_23:00:01/99_Mail_Warning_URL

## Part 2 : Detailed description

### Publishers' deposit : AbesBacon : Traite_OwnCloud.sh

Files are pushed by publishers to ABES's owncloud server.
The Traite_OwnCloud.sh script put them onto begonia server.

The script create an input file for CheckMajEditeurs script containing the list of files to be processed ; files modified since last running.

#### Configuration of Traite_OwnCloud.sh

```         
conf 
│ 
...
├── KBART_Global_Template_2016-04-26.tsv 
└── Traite_OwnCloud 
    └── AbesBacon 
        └── 00_EditeursATraiter_DefinisParABES.txt
```

The 00_EditeursATraiter_DefinisParABES.txt file contains the list of editors to be processed.
```         
BNF
Brepols
CAIRN
CIEPS
Couperin
...
TechniquesIngenieur
ProjectMuse ---
```
#### CheckMajEditeur.sh configuration for AbesBacon
```
conf 
│ 
...
├── CheckMajEditeurs_ahe
│   ├── AbesBacon
│   │   ├── TS_04_CorrectionsDuNomDuFichier.tsv
│   │   ├── TS_08_FichiersADupliquerDansDerniereVersion.txt
│   │   ├── TS_15_Mail.conf
│   │   └── TS_15_Mail.conf.4git
...
    ├── TC_15_Mail.conf
    └── TC_15_Mail.conf.4git

```
### Recovery from publishers : Autre (others)

Files are fetch from publishers web site by a curl request.

#### CheckMajEditeur.sh configuration for Autre
```
conf 
│ 
...
├── CheckMajEditeurs_ahe
...
    ├── Autre
    │   ├── TS_01_URLsATraiter.tsv
    │   ├── TS_15_Mail.conf
    │   └── TS_15_Mail.conf.4git
    ├── TC_15_Mail.conf
    └── TC_15_Mail.conf.4git

```
The file TS_01_URLsATraiter.tsv contains the list of URLs to be retrieved.
```
ACM:Export ACM books	ACM_GLOBAL_ALLEBOOKS	https://dl.acm.org/feeds/acm_kbart_books.txt	acm_kbart_books
...
JSTOR:Arts & Sciences I	JSTOR_COUPERIN_ARTS-AND-SCIENCES-I	https://www.jstor.org/kbart/collections/as	JSTOR_Global_Arts&SciencesICollection_2023-02-17
...
CUP:CCO	CUP_GLOBAL_CCO	https://www.cambridge.org/core/services/aop-cambridge-core/kbart/create/bespoke/0FA3FCA4468F7A8E15F0414727CCE50F	CUP_Cambridge_Companions_Online
...
ELSEVIER:BMF	ELSEVIER_COUPERIN_BIBLIOTHEQUE-MEDICALE-FRANCAISE	https://holdings.sciencedirect.com/holdings/productReport.url?packageId=38190&productId=34	ScienceDirectStandard_Global_ElsevierMassonFrenchLanguageTitles
...
EMS:Books KBART	EMS_GLOBAL_ALLEBOOKS	https://ems.press/files/standalone/metadata/books/kbart/EMSPress_Global_AllBooks.txt	EMSPress_Global_AllBooks
ENI:Eni KBART	ENI_GLOBAL_ALLTITLES	http://download.mediapluspro.com/BN/FR/current/Kbart/kbart.csv	kbart
HARMATTAN:L'Harmattan Harmathèque Allebooks	HARMATTAN_GLOBAL_HARMATHEQUE-ALLEBOOKS	https://www.editions-harmattan.fr/_uploads/harmatheque_Global_AllEbooks_kbart.txt	harmatheque_Global_AllEbooks_kbart
...
PROJECTMUSE:Project Muse Open Access Books	PROJECTMUSE_GLOBAL_OA-EBOOKS	https://about.muse.jhu.edu/lib/metadata?format=kbart&content=book&include=oa&filename=open_access_books&no_auth=1	open_access_books
...
THIEME:Book List - Text File	THIEME_GLOBAL_ALLEBOOKS	https://www.thieme-connect.com/products/ebooks/kbart/thiemeconnectcomebooks_AllTitles.txt	thiemeconnectcomebooks_AllTitles
THIEME:Journals Listing - Text File	THIEME_GLOBAL_ALLJOURNALS	https://www.thieme-connect.com/products/ejournals/kbart/thiemeconnectcomejournals_AllTitles.txt	thiemeconnectcomejournals_AllTitles
``` 
...
to be continued ...

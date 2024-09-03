# Set of bash scripts for importing KBart files
## Origin of KBart files
### By publishers' deposit
Files are pushed by publishers to ABES's owncloud server.
The Traite_OwnCloud.sh script put them onto begonia server. 
### By recovery from publishers
Files are fetch from publishers web site by a curl request.
## Processing Files
New files are compared to archived files ; if there are some differences a diff html file is generated showing them.
And finally a summary file of the modified files is created.
That's the job of the CheckMajEditeur.sh script that sends a summary mail.
### some details
Each script execution is traced into a rundir directory according to the following directory tree.
Configuration files are stored in a conf directory.

The schema is  : 
```
├── MajEditeurs_ahe
│   ├── Archive
│   │   ├── AbesBacon
│   │   │   ├── BNF_GLOBAL_GALLICA-ALLJOURNALS
...
│   │   │   └── TI_Global_VieillissementPathologiesEtRehabilitationDuBatiment
│   │   ├── Autre
│   │   │   ├── 19th_Century_British_Pamphlets
...
│   │   │   └── wiley_all_obooks_2022-07-01-1657648471610
...
│   ├── bin
│   │   ├── checks
│   │   └── soundex
│   ├── conf
│   │   ├── CheckMajEditeurs_ahe
│   │   │   ├── AbesBacon
│   │   │   └── Autre
│   │   └── Traite_OwnCloud_ahe
│   │       └── AbesBacon
│   ├── DerniereVersion
│   │   ├── AbesBacon
│   │   └── Autre
│   ├── Doc
│   └── rundir
│       ├── CheckMajEditeurs_ahe
│       │   ├── AbesBacon
│       │   │   └── 2024-09-02_21:45:01
│       │   │       ├── 03
│       │   │       ├── 04
│       │   │       ├── 05
│       │   │       ├── 06
│       │   │       └── 07_Diff
│       │   └── Autre
│       │       └── 2024-09-02_23:00:02
│       │           ├── 03
│       │           ├── 04
│       │           ├── 05
│       │           ├── 06
│       │           └── 07_Diff
│       └── Traite_OwnCloud_ahe
│           └── AbesBacon
│               └── 2024-09-02_21:35:01
```
Files are copied as many time as needed ; this is done for tracking or debugging purpose.

Log files are under <running date> directory : 99_log, 99_Mail, 99_Mail_Warning .

... to be continued ...

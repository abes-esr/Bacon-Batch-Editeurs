---
editor_options: 
  markdown: 
    wrap: sentence
---

# Set of bash scripts for importing KBart files

## Part 1 : Global description

### Origin of KBart files

#### By publishers' deposit : AbesBacon

Files are pushed by publishers to ABES's owncloud server.\
The Traite_OwnCloud.sh script put them onto begonia server.

#### By recovery from publishers : Autre (others)

Files are fetch from publishers web site by a curl request.

### Processing Files

New files are compared to archived files ; if there are any differences an html diff file is generated to display them.\
New files if different are stored in Archive directory.\

At the end of the process, a summary file of the changed files is created.\

That's the job of the CheckMajEditeur.sh script that finally sends a summary mail.

### some details

The tree of involved directories is :\

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

Each script execution is logged into a **rundir** directory as **/rundir/**<program name>/<editor>/<running date> .\

Configuration files are stored in a **conf** directory.

The process is divided into numbered steps and the data files are copied as many times as necessary; this is done for tracking or debugging purposes.

Log files are under **rundir** directory : 99_log, 99_Mail, 99_Mail_Warning .

## Part 2 : Detailed description

### Publishers' deposit : AbesBacon : Traite_OwnCloud.sh

Files are pushed by publishers to ABES's owncloud server.\
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

The 00_EditeursATraiter_DefinisParABES.txt file contains the list of editors to be processed.\

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

### Recovery from publishers : Autre (others)

Files are fetch from publishers web site by a curl request.
...
to be continued ...

# ZPROJECT_GSU26SAP08
# ABAP Report Modernization Analyzer

## 1. Purpose

Analyze legacy ABAP reports and create structured migration metadata.

The current architecture uses:

- A generic RAP metadata service
- A reusable ABAP analysis engine
- A future generic SAPUI5 preview runtime
- Optional dedicated RAP promotion

The analyzer does not generate RAP objects for every analyzed report.

## 2. System Requirements

- SAP S/4HANA 2022 On-Premise
- SAP HANA 2.0
- OData V4 and RAP support
- Eclipse ADT
- abapGit

Development environment used:

- Eclipse 2026-03
- ABAP Development Tools 3.58.2

## 3. Architecture

Legacy ABAP Reports
        |
        v
Source Repository
        |
        v
Scanner and Parser
        |
        v
Semantic Resolver
        |
        v
Recommendation Engine
        |
        v
RAP Metadata Repository

## 4. Main Packages

- ZMIG_CORE
- ZMIG_ANALYZER
- ZMIG_RAP
- ZMIG_RUNTIME
- ZMIG_LEGACY_POC

## 5. Main RAP Objects

- ZI_MIG_REPORT_HD
- ZC_MIG_REPORT_HD
- ZCL_BP_MIG_REPORT_HD
- ZUI_ANALYZER_SERVICE

## 6. External Dependencies

### abap2xlsx

Required by the Excel export implementation.

Required classes include:

- ZCL_EXCEL
- ZCL_EXCEL_WORKSHEET
- ZIF_EXCEL_WRITER
- ZCL_EXCEL_WRITER_2007

## 7. Installation

1. Install external dependencies.
2. Clone the repository using abapGit.
3. Activate database tables.
4. Activate interfaces and classes.
5. Activate CDS interface views.
6. Activate behavior definitions.
7. Activate projection views.
8. Activate the service definition.
9. Create or activate the OData V4 service binding.

## 8. Current Scope

Supported:

- Active ABAP report source
- Static INCLUDE
- PARAMETERS
- SELECT-OPTIONS
- Static Open SQL
- Function Module calls
- PERFORM
- SUBMIT
- Basic migration recommendations

Not yet supported:

- Generic Preview Runtime
- Dynamic SQL
- Complete call graph
- Editable ALV
- Tree ALV
- Dynamic screens
- Regression comparison

## 9. Branch Strategy

- main: stable source
- refactor/*: architecture refactoring
- feature/*: new features
- fix/*: bug fixes

## 10. Legacy Proof of Concept

XCO-based per-report generation is retained under the
ZMIG_LEGACY_POC package for reference only.

It is not part of the core analyzer runtime.

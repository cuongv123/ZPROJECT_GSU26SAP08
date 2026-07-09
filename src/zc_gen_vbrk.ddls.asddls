@EndUserText.label: 'Generated Projection for VBRK'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@UI.headerInfo: { typeName: 'Item', typeNamePlural: 'Items' }
define root view entity ZC_GEN_VBRK
  as projection on ZI_GEN_VBRK
{
 
      @UI.lineItem: [{ position: 10 }]
      @EndUserText.label: 'Billing Doc.'
  key VBELN,
 
      @UI.lineItem: [{ position: 20 }]
      @EndUserText.label: 'Billing Type'
      FKART,
 
      @UI.lineItem: [{ position: 30 }]
      @EndUserText.label: 'BillingCategory'
      FKTYP,
 
      @UI.lineItem: [{ position: 40 }]
      @EndUserText.label: 'Document Cat.'
      VBTYP,
 
      @UI.lineItem: [{ position: 50 }]
      @EndUserText.label: 'Doc. Currency'
      WAERK,
 
      @UI.lineItem: [{ position: 60 }]
      @EndUserText.label: 'Sales Org.'
      VKORG,
 
      @UI.lineItem: [{ position: 70 }]
      @EndUserText.label: 'Distr. Channel'
      VTWEG,
 
      @UI.lineItem: [{ position: 80 }]
      @EndUserText.label: 'Pric. Procedure'
      KALSM,
 
      @UI.lineItem: [{ position: 90 }]
      @EndUserText.label: 'Doc. Condition'
      KNUMV,
 
      @UI.lineItem: [{ position: 100 }]
      @EndUserText.label: 'Shp.Cond.'
      VSBED,
 
      @UI.lineItem: [{ position: 110 }]
      @EndUserText.label: 'Billing Date'
      FKDAT,
 
      @UI.lineItem: [{ position: 120 }]
      @EndUserText.label: 'Document Number'
      BELNR,
 
      @UI.lineItem: [{ position: 130 }]
      @EndUserText.label: 'Fiscal Year'
      GJAHR,
 
      @UI.lineItem: [{ position: 140 }]
      @EndUserText.label: 'Posting Period'
      POPER,
 
      @UI.lineItem: [{ position: 150 }]
      @EndUserText.label: 'CustPrice Group'
      KONDA,
 
      @UI.lineItem: [{ position: 160 }]
      @EndUserText.label: 'Customer Group'
      KDGRP,
 
      @UI.lineItem: [{ position: 170 }]
      @EndUserText.label: 'Sales District'
      BZIRK,
 
      @UI.lineItem: [{ position: 180 }]
      @EndUserText.label: 'Price List Tp.'
      PLTYP,
 
      @UI.lineItem: [{ position: 190 }]
      @EndUserText.label: 'Incoterms'
      INCO1,
 
      @UI.lineItem: [{ position: 200 }]
      @EndUserText.label: 'Incoterms 2'
      INCO2,
 
      @UI.lineItem: [{ position: 210 }]
      @EndUserText.label: 'Posting Status'
      RFBSK,
 
      @UI.lineItem: [{ position: 220 }]
      @EndUserText.label: 'Man.Inv.Maint.'
      MRNKZ,
 
      @UI.lineItem: [{ position: 230 }]
      @EndUserText.label: 'Exch.Rate Acct.'
      KURRF,
 
      @UI.lineItem: [{ position: 240 }]
      @EndUserText.label: 'Set Exchange Rt'
      CPKUR,
 
      @UI.lineItem: [{ position: 250 }]
      @EndUserText.label: 'Add. Value Days'
      VALTG,
 
      @UI.lineItem: [{ position: 260 }]
      @EndUserText.label: 'Fixed Val. Date'
      VALDT,
 
      @UI.lineItem: [{ position: 270 }]
      @EndUserText.label: 'Pyt Terms'
      ZTERM,
 
      @UI.lineItem: [{ position: 280 }]
      @EndUserText.label: 'Payt Method'
      ZLSCH,
 
      @UI.lineItem: [{ position: 290 }]
      @EndUserText.label: 'AccAssmtGrpCust'
      KTGRD,
 
      @UI.lineItem: [{ position: 300 }]
      @EndUserText.label: 'Dest. Ctry/Reg'
      LAND1,
 
      @UI.lineItem: [{ position: 310 }]
      @EndUserText.label: 'Region'
      REGIO,
 
      @UI.lineItem: [{ position: 320 }]
      @EndUserText.label: 'County Code'
      COUNC,
 
      @UI.lineItem: [{ position: 330 }]
      @EndUserText.label: 'City Code'
      CITYC,
 
      @UI.lineItem: [{ position: 340 }]
      @EndUserText.label: 'Company Code'
      BUKRS,
 
      @UI.lineItem: [{ position: 350 }]
      @EndUserText.label: 'Tax Cls.1 Cust.'
      TAXK1,
 
      @UI.lineItem: [{ position: 360 }]
      @EndUserText.label: 'Tax Cls.2 Cust.'
      TAXK2,
 
      @UI.lineItem: [{ position: 370 }]
      @EndUserText.label: 'Tax Cls.3 Cust.'
      TAXK3,
 
      @UI.lineItem: [{ position: 380 }]
      @EndUserText.label: 'Tax Cls.4 Cust.'
      TAXK4,
 
      @UI.lineItem: [{ position: 390 }]
      @EndUserText.label: 'Tax Cls.5 Cust.'
      TAXK5,
 
      @UI.lineItem: [{ position: 400 }]
      @EndUserText.label: 'Tax Cls.6 Cust.'
      TAXK6,
 
      @UI.lineItem: [{ position: 410 }]
      @EndUserText.label: 'Tax Cls.7 Cust.'
      TAXK7,
 
      @UI.lineItem: [{ position: 420 }]
      @EndUserText.label: 'Tax Cls.8 Cust.'
      TAXK8,
 
      @UI.lineItem: [{ position: 430 }]
      @EndUserText.label: 'Tax Cls.9 Cust.'
      TAXK9,
 
      @UI.lineItem: [{ position: 440 }]
      @EndUserText.label: 'Net Value'
      NETWR,
 
      @UI.lineItem: [{ position: 450 }]
      @EndUserText.label: 'Comb. Criteria'
      ZUKRI,
 
      @UI.lineItem: [{ position: 460 }]
      @EndUserText.label: 'Created By'
      ERNAM,
 
      @UI.lineItem: [{ position: 470 }]
      @EndUserText.label: 'Time'
      ERZET,
 
      @UI.lineItem: [{ position: 480 }]
      @EndUserText.label: 'Created On'
      ERDAT,
 
      @UI.lineItem: [{ position: 490 }]
      @EndUserText.label: 'Update Group'
      STAFO,
 
      @UI.lineItem: [{ position: 500 }]
      @EndUserText.label: 'Payer'
      KUNRG,
 
      @UI.lineItem: [{ position: 510 }]
      @EndUserText.label: 'Sold-to Party'
      KUNAG,
 
      @UI.lineItem: [{ position: 520 }]
      @EndUserText.label: 'Dunning Area'
      MABER,
 
      @UI.lineItem: [{ position: 530 }]
      @EndUserText.label: 'Stats. Currency'
      STWAE,
 
      @UI.lineItem: [{ position: 540 }]
      @EndUserText.label: 'VAT Reg. No.'
      STCEG,
 
      @UI.lineItem: [{ position: 550 }]
      @EndUserText.label: 'Changed On'
      AEDAT,
 
      @UI.lineItem: [{ position: 560 }]
      @EndUserText.label: 'Canceld Bill.Dc'
      SFAKN,
 
      @UI.lineItem: [{ position: 570 }]
      @EndUserText.label: 'Agreement'
      KNUMA,
 
      @UI.lineItem: [{ position: 580 }]
      @EndUserText.label: 'Inv. List Type'
      FKART_RL,
 
      @UI.lineItem: [{ position: 590 }]
      @EndUserText.label: 'Inv.Lst Bill.Dt'
      FKDAT_RL,
 
      @UI.lineItem: [{ position: 600 }]
      @EndUserText.label: 'Exch. Rate Type'
      KURST,
 
      @UI.lineItem: [{ position: 610 }]
      @EndUserText.label: 'Dunning key'
      MSCHL,
 
      @UI.lineItem: [{ position: 620 }]
      @EndUserText.label: 'Dunn. Block'
      MANSP,
 
      @UI.lineItem: [{ position: 630 }]
      @EndUserText.label: 'Division'
      SPART,
 
      @UI.lineItem: [{ position: 640 }]
      @EndUserText.label: 'Cred.Contr.Area'
      KKBER,
 
      @UI.lineItem: [{ position: 650 }]
      @EndUserText.label: 'Credit Account'
      KNKLI,
 
      @UI.lineItem: [{ position: 660 }]
      @EndUserText.label: 'Currency'
      CMWAE,
 
      @UI.lineItem: [{ position: 670 }]
      @EndUserText.label: 'Exchange Rate'
      CMKUF,
 
      @UI.lineItem: [{ position: 680 }]
      @EndUserText.label: 'HierTypePricing'
      HITYP_PR,
 
      @UI.lineItem: [{ position: 690 }]
      @EndUserText.label: 'Cust. Hier. Relvnc.'
      CUSTH_UNIV_SALES_RELVNCE,
 
      @UI.lineItem: [{ position: 700 }]
      @EndUserText.label: 'Cust. Hier. Br. UUID'
      CUSTH_BRANCH_UUID,
 
      @UI.lineItem: [{ position: 710 }]
      @EndUserText.label: 'Cust. Reference'
      BSTNK_VF,
 
      @UI.lineItem: [{ position: 720 }]
      @EndUserText.label: 'Trading Partner'
      VBUND,
 
      @UI.lineItem: [{ position: 730 }]
      @EndUserText.label: 'AccrualBillType'
      FKART_AB,
 
      @UI.lineItem: [{ position: 740 }]
      @EndUserText.label: 'Application'
      KAPPL,
 
      @UI.lineItem: [{ position: 750 }]
      @EndUserText.label: 'Tax Depar. C/R'
      LANDTX,
 
      @UI.lineItem: [{ position: 760 }]
      @EndUserText.label: 'OriginSlsTxNo.'
      STCEG_H,
 
      @UI.lineItem: [{ position: 770 }]
      @EndUserText.label: 'CtryRgnSlsTxNo.'
      STCEG_L,
 
      @UI.lineItem: [{ position: 780 }]
      @EndUserText.label: 'Reference'
      XBLNR,
 
      @UI.lineItem: [{ position: 790 }]
      @EndUserText.label: 'Assignment'
      ZUONR,
 
      @UI.lineItem: [{ position: 800 }]
      @EndUserText.label: 'Tax Amount'
      MWSBK,
 
      @UI.lineItem: [{ position: 810 }]
      @EndUserText.label: 'Logical system'
      LOGSYS,
 
      @UI.lineItem: [{ position: 820 }]
      @EndUserText.label: 'Canceled'
      FKSTO,
 
      @UI.lineItem: [{ position: 830 }]
      @EndUserText.label: 'EU Triang. Deal'
      XEGDR,
 
      @UI.lineItem: [{ position: 840 }]
      @EndUserText.label: 'Paym.Ca.Pl.No.'
      RPLNR,
 
      @UI.lineItem: [{ position: 850 }]
      @EndUserText.label: 'Tax Type'
      J_1AFITP,
 
      @UI.lineItem: [{ position: 860 }]
      @EndUserText.label: 'Translatn Date'
      KURRF_DAT,
 
      @UI.lineItem: [{ position: 870 }]
      @EndUserText.label: 'Payment Ref.'
      KIDNO,
 
      @UI.lineItem: [{ position: 880 }]
      @EndUserText.label: 'Part.bank type'
      BVTYP,
 
      @UI.lineItem: [{ position: 890 }]
      @EndUserText.label: 'Number of Pages'
      NUMPG,
 
      @UI.lineItem: [{ position: 900 }]
      @EndUserText.label: 'Business place'
      BUPLA,
 
      @UI.lineItem: [{ position: 910 }]
      @EndUserText.label: 'Contract Acct'
      VKONT,
 
      @UI.lineItem: [{ position: 920 }]
      @EndUserText.label: 'Add. Fin.Status'
      FKK_DOCSTAT,
 
      @UI.lineItem: [{ position: 930 }]
      @EndUserText.label: ''
      NRZAS,
 
      @UI.lineItem: [{ position: 940 }]
      @EndUserText.label: 'Billing Indicator'
      SPE_BILLING_IND,
 
      @UI.lineItem: [{ position: 950 }]
      @EndUserText.label: 'Contract'
      VTREF,
 
      @UI.lineItem: [{ position: 960 }]
      @EndUserText.label: 'Source System'
      FK_SOURCE_SYS,
 
      @UI.lineItem: [{ position: 970 }]
      @EndUserText.label: 'Serv. Bill.Cat.'
      FKTYP_CRM,
 
      @UI.lineItem: [{ position: 980 }]
      @EndUserText.label: 'Reversal Reason'
      STGRD,
 
      @UI.lineItem: [{ position: 990 }]
      @EndUserText.label: 'Time Stamp'
      CHANGED_ON,
 
      @UI.lineItem: [{ position: 1000 }]
      @EndUserText.label: 'Export'
      EXPKZ,
 
      @UI.lineItem: [{ position: 1010 }]
      @EndUserText.label: 'Foreign Trade DataNr'
      EXNUM,
 
      @UI.lineItem: [{ position: 1020 }]
      @EndUserText.label: 'LettOfCredCrcy'
      AKWAE,
 
      @UI.lineItem: [{ position: 1030 }]
      @EndUserText.label: 'LettofCredRate'
      AKKUR,
 
      @UI.lineItem: [{ position: 1040 }]
      @EndUserText.label: 'Financ.Doc.No.'
      LCNUM,
 
      @UI.lineItem: [{ position: 1050 }]
      @EndUserText.label: 'Data Aging'
      _DATAAGING,
 
      @UI.lineItem: [{ position: 1060 }]
      @EndUserText.label: 'Posting Status'
      BUCHK,
 
      @UI.lineItem: [{ position: 1070 }]
      @EndUserText.label: 'Overall Status'
      GBSTK,
 
      @UI.lineItem: [{ position: 1080 }]
      @EndUserText.label: 'Inv.List Status'
      RELIK,
 
      @UI.lineItem: [{ position: 1090 }]
      @EndUserText.label: 'All Items'
      UVALS,
 
      @UI.lineItem: [{ position: 1100 }]
      @EndUserText.label: 'Prcg – All Itms'
      UVPRS,
 
      @UI.lineItem: [{ position: 1110 }]
      @EndUserText.label: 'Clearing Status'
      CLRST,
 
      @UI.lineItem: [{ position: 1120 }]
      @EndUserText.label: 'Ord.Rel.BillgSt'
      FKSAK,
 
      @UI.lineItem: [{ position: 1130 }]
      @EndUserText.label: 'Ord-Rel.Bill.Ty'
      FKARA,
 
      @UI.lineItem: [{ position: 1140 }]
      @EndUserText.label: 'Status'
      VF_STATUS,
 
      @UI.lineItem: [{ position: 1150 }]
      @EndUserText.label: 'Issue Type'
      VF_TODO,
 
      @UI.lineItem: [{ position: 1160 }]
      @EndUserText.label: 'Status'
      BDR_STATUS,
 
      @UI.lineItem: [{ position: 1170 }]
      @EndUserText.label: 'BDR Source Document'
      BDR_REF,
 
      @UI.lineItem: [{ position: 1180 }]
      @EndUserText.label: 'BDR Source System'
      BDR_REF_LOGSYS,
 
      @UI.lineItem: [{ position: 1190 }]
      @EndUserText.label: 'BDR Src. Doc. Cat.'
      BDR_REF_VBTYP,
 
      @UI.lineItem: [{ position: 1200 }]
      @EndUserText.label: 'Status'
      PBD_STATUS,
 
      @UI.lineItem: [{ position: 1210 }]
      @EndUserText.label: 'Rejection Sts'
      ABSTK,
 
      @UI.lineItem: [{ position: 1220 }]
      @EndUserText.label: 'Draft Indicator'
      DRAFT,
 
      @UI.lineItem: [{ position: 1230 }]
      @EndUserText.label: 'SD Document'
      ACTIVEDOCUMENT,
 
      @UI.lineItem: [{ position: 1240 }]
      @EndUserText.label: 'Currency'
      GRWCU,
 
      @UI.lineItem: [{ position: 1250 }]
      @EndUserText.label: 'Document Type'
      BLART,
 
      @UI.lineItem: [{ position: 1260 }]
      @EndUserText.label: 'Intrastat rel.'
      INTRA_REL,
 
      @UI.lineItem: [{ position: 1270 }]
      @EndUserText.label: 'exclude Intra'
      INTRA_EXCL,
 
      @UI.lineItem: [{ position: 1280 }]
      @EndUserText.label: 'Relevant for Accrual'
      ACCRREL,
 
      @UI.lineItem: [{ position: 1290 }]
      @EndUserText.label: 'Paym Split Predec SD'
      PSPSD,
 
      @UI.lineItem: [{ position: 1300 }]
      @EndUserText.label: 'Approval Status'
      APM_APPROVAL_STATUS,
 
      @UI.lineItem: [{ position: 1310 }]
      @EndUserText.label: 'Apprvl Req. Rsn ID'
      APM_APPROVAL_REASON,
 
      @UI.lineItem: [{ position: 1320 }]
      @EndUserText.label: 'SrceDocExtCommSystTy'
      SRCEDOC_EXT_COMM_SYST_TYPE,
 
      @UI.lineItem: [{ position: 1330 }]
      @EndUserText.label: 'Sppl. No. Plnt'
      ICO_LIFNR,
 
      @UI.lineItem: [{ position: 1340 }]
      @EndUserText.label: 'Branch Code'
      J_1TPBUPL,
 
      @UI.lineItem: [{ position: 1350 }]
      @EndUserText.label: 'Inco. Version'
      INCOV,
 
      @UI.lineItem: [{ position: 1360 }]
      @EndUserText.label: 'Inco. Location1'
      INCO2_L,
 
      @UI.lineItem: [{ position: 1370 }]
      @EndUserText.label: 'Inco. Location2'
      INCO3_L,
 
      @UI.lineItem: [{ position: 1380 }]
      @EndUserText.label: 'SDM Versioning'
      SDM_VERSION,
 
      @UI.lineItem: [{ position: 1390 }]
      @EndUserText.label: ''
      DUMMY_BILLINGDOC_INCL_EEW_PS,
 
      @UI.lineItem: [{ position: 1400 }]
      @EndUserText.label: ''
      GLO_LOG_REF1_HD,
 
      @UI.lineItem: [{ position: 1410 }]
      @EndUserText.label: 'Annexing Package'
      ZAPCGKH,
 
      @UI.lineItem: [{ position: 1420 }]
      @EndUserText.label: 'Ann.Package Extend'
      APCGK_EXTENDH,
 
      @UI.lineItem: [{ position: 1430 }]
      @EndUserText.label: 'Annexing base date'
      ZABDATH,
 
      @UI.lineItem: [{ position: 1440 }]
      @EndUserText.label: 'DPC relevant'
      DPC_REL,
 
      @UI.lineItem: [{ position: 1450 }]
      @EndUserText.label: 'Initial Doc.'
      AD01BASDOC,
 
      @UI.lineItem: [{ position: 1460 }]
      @EndUserText.label: 'A&D Bill. Rule'
      AD01FAREG,
 
      @UI.lineItem: [{ position: 1470 }]
      @EndUserText.label: 'Voucher No.'
      VCHRNMBR,
 
      @UI.lineItem: [{ position: 1480 }]
      @EndUserText.label: 'ETM-Rel. Ind.'
      J_3GKBAUL,
 
      @UI.lineItem: [{ position: 1490 }]
      @EndUserText.label: 'Intern./extern.'
      J_3GKENIE,
 
      @UI.lineItem: [{ position: 1500 }]
      @EndUserText.label: 'Ship-to Party'
      KUNWE,
 
      @UI.lineItem: [{ position: 1510 }]
      @EndUserText.label: 'Mandate Ref.'
      MNDID,
 
      @UI.lineItem: [{ position: 1520 }]
      @EndUserText.label: 'Payment Type'
      PAY_TYPE,
 
      @UI.lineItem: [{ position: 1530 }]
      @EndUserText.label: 'SEPA-Relevant'
      SEPON,
 
      @UI.lineItem: [{ position: 1540 }]
      @EndUserText.label: 'SEPA-Relevant'
      MNDVG,
 
      @UI.lineItem: [{ position: 1550 }]
      @EndUserText.label: 'PaymMethod'
      SPPAYM,
 
      @UI.lineItem: [{ position: 1560 }]
      @EndUserText.label: 'Sales Order'
      SPPORD
}

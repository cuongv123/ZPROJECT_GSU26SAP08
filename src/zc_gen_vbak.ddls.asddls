@EndUserText.label: 'Generated Projection for VBAK'
@AccessControl.authorizationCheck: #NOT_REQUIRED
@UI.headerInfo: { typeName: 'Item', typeNamePlural: 'Items' }
define root view entity ZC_GEN_VBAK
  as projection on ZI_GEN_VBAK
{
 
      @UI.lineItem: [{ position: 10 }]
      @EndUserText.label: 'Sales Document'
  key VBELN,
 
      @UI.lineItem: [{ position: 20 }]
      @EndUserText.label: 'Created On'
      ERDAT,
 
      @UI.lineItem: [{ position: 30 }]
      @EndUserText.label: 'Time'
      ERZET,
 
      @UI.lineItem: [{ position: 40 }]
      @EndUserText.label: 'Created By'
      ERNAM,
 
      @UI.lineItem: [{ position: 50 }]
      @EndUserText.label: 'Valid From'
      ANGDT,
 
      @UI.lineItem: [{ position: 60 }]
      @EndUserText.label: 'Valid To'
      BNDDT,
 
      @UI.lineItem: [{ position: 70 }]
      @EndUserText.label: 'Document Date'
      AUDAT,
 
      @UI.lineItem: [{ position: 80 }]
      @EndUserText.label: 'Document Cat.'
      VBTYP,
 
      @UI.lineItem: [{ position: 90 }]
      @EndUserText.label: 'Transact.Group'
      TRVOG,
 
      @UI.lineItem: [{ position: 100 }]
      @EndUserText.label: 'Sales Doc. Type'
      AUART,
 
      @UI.lineItem: [{ position: 110 }]
      @EndUserText.label: 'Order Reason'
      AUGRU,
 
      @UI.lineItem: [{ position: 120 }]
      @EndUserText.label: 'Warranty Start'
      GWLDT,
 
      @UI.lineItem: [{ position: 130 }]
      @EndUserText.label: 'Collective No.'
      SUBMI,
 
      @UI.lineItem: [{ position: 140 }]
      @EndUserText.label: 'Delivery Block'
      LIFSK,
 
      @UI.lineItem: [{ position: 150 }]
      @EndUserText.label: 'Billing Block'
      FAKSK,
 
      @UI.lineItem: [{ position: 160 }]
      @EndUserText.label: 'Net Value'
      NETWR,
 
      @UI.lineItem: [{ position: 170 }]
      @EndUserText.label: 'Doc. Currency'
      WAERK,
 
      @UI.lineItem: [{ position: 180 }]
      @EndUserText.label: 'Sales Org.'
      VKORG,
 
      @UI.lineItem: [{ position: 190 }]
      @EndUserText.label: 'Distr. Channel'
      VTWEG,
 
      @UI.lineItem: [{ position: 200 }]
      @EndUserText.label: 'Division'
      SPART,
 
      @UI.lineItem: [{ position: 210 }]
      @EndUserText.label: 'Sales Group'
      VKGRP,
 
      @UI.lineItem: [{ position: 220 }]
      @EndUserText.label: 'Sales Office'
      VKBUR,
 
      @UI.lineItem: [{ position: 230 }]
      @EndUserText.label: 'Business Area'
      GSBER,
 
      @UI.lineItem: [{ position: 240 }]
      @EndUserText.label: 'Business Area'
      GSKST,
 
      @UI.lineItem: [{ position: 250 }]
      @EndUserText.label: 'Valid From'
      GUEBG,
 
      @UI.lineItem: [{ position: 260 }]
      @EndUserText.label: 'Valid To'
      GUEEN,
 
      @UI.lineItem: [{ position: 270 }]
      @EndUserText.label: 'Doc. Condition'
      KNUMV,
 
      @UI.lineItem: [{ position: 280 }]
      @EndUserText.label: 'Reqd Deliv Date'
      VDATU,
 
      @UI.lineItem: [{ position: 290 }]
      @EndUserText.label: 'Deliv Date Rule'
      DELIVERY_DATE_TYPE_RULE,
 
      @UI.lineItem: [{ position: 300 }]
      @EndUserText.label: 'Prop.date type'
      VPRGR,
 
      @UI.lineItem: [{ position: 310 }]
      @EndUserText.label: 'Complete Dlv.'
      AUTLF,
 
      @UI.lineItem: [{ position: 320 }]
      @EndUserText.label: 'Original system'
      VBKLA,
 
      @UI.lineItem: [{ position: 330 }]
      @EndUserText.label: 'Indicator'
      VBKLT,
 
      @UI.lineItem: [{ position: 340 }]
      @EndUserText.label: 'Pric. Procedure'
      KALSM,
 
      @UI.lineItem: [{ position: 350 }]
      @EndUserText.label: 'Shp.Cond.'
      VSBED,
 
      @UI.lineItem: [{ position: 360 }]
      @EndUserText.label: 'Ord-Rel.Bill.Ty'
      FKARA,
 
      @UI.lineItem: [{ position: 370 }]
      @EndUserText.label: 'Probability'
      AWAHR,
 
      @UI.lineItem: [{ position: 380 }]
      @EndUserText.label: 'Description'
      KTEXT,
 
      @UI.lineItem: [{ position: 390 }]
      @EndUserText.label: 'Cust. Reference'
      BSTNK,
 
      @UI.lineItem: [{ position: 400 }]
      @EndUserText.label: 'Pur. Ord. Type'
      BSARK,
 
      @UI.lineItem: [{ position: 410 }]
      @EndUserText.label: 'Cust. Ref. Date'
      BSTDK,
 
      @UI.lineItem: [{ position: 420 }]
      @EndUserText.label: 'Supplement'
      BSTZD,
 
      @UI.lineItem: [{ position: 430 }]
      @EndUserText.label: 'Your Reference'
      IHREZ,
 
      @UI.lineItem: [{ position: 440 }]
      @EndUserText.label: 'Name'
      BNAME,
 
      @UI.lineItem: [{ position: 450 }]
      @EndUserText.label: 'Telephone'
      TELF1,
 
      @UI.lineItem: [{ position: 460 }]
      @EndUserText.label: 'No.of Contacts'
      MAHZA,
 
      @UI.lineItem: [{ position: 470 }]
      @EndUserText.label: 'Last Contact Dt'
      MAHDT,
 
      @UI.lineItem: [{ position: 480 }]
      @EndUserText.label: 'Sold-to Party'
      KUNNR,
 
      @UI.lineItem: [{ position: 490 }]
      @EndUserText.label: 'Cost Center'
      KOSTL,
 
      @UI.lineItem: [{ position: 500 }]
      @EndUserText.label: 'Update Group'
      STAFO,
 
      @UI.lineItem: [{ position: 510 }]
      @EndUserText.label: 'Stats. Currency'
      STWAE,
 
      @UI.lineItem: [{ position: 520 }]
      @EndUserText.label: 'Changed On'
      AEDAT,
 
      @UI.lineItem: [{ position: 530 }]
      @EndUserText.label: 'Customer Grp 1'
      KVGR1,
 
      @UI.lineItem: [{ position: 540 }]
      @EndUserText.label: 'Customer Grp 2'
      KVGR2,
 
      @UI.lineItem: [{ position: 550 }]
      @EndUserText.label: 'Customer Grp 3'
      KVGR3,
 
      @UI.lineItem: [{ position: 560 }]
      @EndUserText.label: 'Customer Grp 4'
      KVGR4,
 
      @UI.lineItem: [{ position: 570 }]
      @EndUserText.label: 'Customer Grp 5'
      KVGR5,
 
      @UI.lineItem: [{ position: 580 }]
      @EndUserText.label: 'Agreement'
      KNUMA,
 
      @UI.lineItem: [{ position: 590 }]
      @EndUserText.label: 'CO Area'
      KOKRS,
 
      @UI.lineItem: [{ position: 600 }]
      @EndUserText.label: 'WBS Element'
      PS_PSP_PNR,
 
      @UI.lineItem: [{ position: 610 }]
      @EndUserText.label: 'Exch. Rate Type'
      KURST,
 
      @UI.lineItem: [{ position: 620 }]
      @EndUserText.label: 'Cred.Contr.Area'
      KKBER,
 
      @UI.lineItem: [{ position: 630 }]
      @EndUserText.label: 'Credit Account'
      KNKLI,
 
      @UI.lineItem: [{ position: 640 }]
      @EndUserText.label: 'Cust.Cred.Group'
      GRUPP,
 
      @UI.lineItem: [{ position: 650 }]
      @EndUserText.label: 'Cred.Rep.Grp'
      SBGRP,
 
      @UI.lineItem: [{ position: 660 }]
      @EndUserText.label: 'Risk Category'
      CTLPC,
 
      @UI.lineItem: [{ position: 670 }]
      @EndUserText.label: 'Currency'
      CMWAE,
 
      @UI.lineItem: [{ position: 680 }]
      @EndUserText.label: 'Release date'
      CMFRE,
 
      @UI.lineItem: [{ position: 690 }]
      @EndUserText.label: 'Next Check'
      CMNUP,
 
      @UI.lineItem: [{ position: 700 }]
      @EndUserText.label: 'Next date'
      CMNGV,
 
      @UI.lineItem: [{ position: 710 }]
      @EndUserText.label: 'Credit Value'
      AMTBL,
 
      @UI.lineItem: [{ position: 720 }]
      @EndUserText.label: 'Credit Man.Timestamp'
      CM_LAST_CHECK,
 
      @UI.lineItem: [{ position: 730 }]
      @EndUserText.label: 'HierTypePricing'
      HITYP_PR,
 
      @UI.lineItem: [{ position: 740 }]
      @EndUserText.label: 'Cust. Hier. Relvnc.'
      CUSTH_UNIV_SALES_RELVNCE,
 
      @UI.lineItem: [{ position: 750 }]
      @EndUserText.label: 'Cust. Hier. Br. UUID'
      CUSTH_BRANCH_UUID,
 
      @UI.lineItem: [{ position: 760 }]
      @EndUserText.label: 'Usage'
      ABRVW,
 
      @UI.lineItem: [{ position: 770 }]
      @EndUserText.label: 'MRP for DS type'
      ABDIS,
 
      @UI.lineItem: [{ position: 780 }]
      @EndUserText.label: 'Reference Doc.'
      VGBEL,
 
      @UI.lineItem: [{ position: 790 }]
      @EndUserText.label: 'Object No. Hdr'
      OBJNR,
 
      @UI.lineItem: [{ position: 800 }]
      @EndUserText.label: 'CCodeToBeBilled'
      BUKRS_VF,
 
      @UI.lineItem: [{ position: 810 }]
      @EndUserText.label: 'Alt.Tax Class.'
      TAXK1,
 
      @UI.lineItem: [{ position: 820 }]
      @EndUserText.label: 'Tax Cls.2 Cust.'
      TAXK2,
 
      @UI.lineItem: [{ position: 830 }]
      @EndUserText.label: 'Tax Cls.3 Cust.'
      TAXK3,
 
      @UI.lineItem: [{ position: 840 }]
      @EndUserText.label: 'Tax Cls.4 Cust.'
      TAXK4,
 
      @UI.lineItem: [{ position: 850 }]
      @EndUserText.label: 'Tax Cls.5 Cust.'
      TAXK5,
 
      @UI.lineItem: [{ position: 860 }]
      @EndUserText.label: 'Tax Cls.6 Cust.'
      TAXK6,
 
      @UI.lineItem: [{ position: 870 }]
      @EndUserText.label: 'Tax Cls.7 Cust.'
      TAXK7,
 
      @UI.lineItem: [{ position: 880 }]
      @EndUserText.label: 'Tax Cls.8 Cust.'
      TAXK8,
 
      @UI.lineItem: [{ position: 890 }]
      @EndUserText.label: 'Tax Cls.9 Cust.'
      TAXK9,
 
      @UI.lineItem: [{ position: 900 }]
      @EndUserText.label: 'Reference'
      XBLNR,
 
      @UI.lineItem: [{ position: 910 }]
      @EndUserText.label: 'Assignment'
      ZUONR,
 
      @UI.lineItem: [{ position: 920 }]
      @EndUserText.label: 'Prec.Doc.Categ.'
      VGTYP,
 
      @UI.lineItem: [{ position: 930 }]
      @EndUserText.label: 'Search Proced.'
      KALSM_CH,
 
      @UI.lineItem: [{ position: 940 }]
      @EndUserText.label: 'Accrual period'
      AGRZR,
 
      @UI.lineItem: [{ position: 950 }]
      @EndUserText.label: 'Order'
      AUFNR,
 
      @UI.lineItem: [{ position: 960 }]
      @EndUserText.label: 'Notification'
      QMNUM,
 
      @UI.lineItem: [{ position: 970 }]
      @EndUserText.label: 'Master Contract'
      VBELN_GRP,
 
      @UI.lineItem: [{ position: 980 }]
      @EndUserText.label: 'Ref.procedure'
      SCHEME_GRP,
 
      @UI.lineItem: [{ position: 990 }]
      @EndUserText.label: 'Check partner'
      ABRUF_PART,
 
      @UI.lineItem: [{ position: 1000 }]
      @EndUserText.label: 'Pick-Up Date'
      ABHOD,
 
      @UI.lineItem: [{ position: 1010 }]
      @EndUserText.label: 'Pick-Up Time'
      ABHOV,
 
      @UI.lineItem: [{ position: 1020 }]
      @EndUserText.label: 'Pick-Up Time'
      ABHOB,
 
      @UI.lineItem: [{ position: 1030 }]
      @EndUserText.label: 'Paym.Ca.Pl.No.'
      RPLNR,
 
      @UI.lineItem: [{ position: 1040 }]
      @EndUserText.label: 'Req. dely time'
      VZEIT,
 
      @UI.lineItem: [{ position: 1050 }]
      @EndUserText.label: 'Tax Dest. Cty/R'
      STCEG_L,
 
      @UI.lineItem: [{ position: 1060 }]
      @EndUserText.label: 'Tax Depar. C/R'
      LANDTX,
 
      @UI.lineItem: [{ position: 1070 }]
      @EndUserText.label: 'EU Triang. Deal'
      XEGDR,
 
      @UI.lineItem: [{ position: 1080 }]
      @EndUserText.label: ''
      ENQUEUE_GRP,
 
      @UI.lineItem: [{ position: 1090 }]
      @EndUserText.label: 'CmlQtyDate'
      DAT_FZAU,
 
      @UI.lineItem: [{ position: 1100 }]
      @EndUserText.label: 'Mat.Avail.Date'
      FMBDAT,
 
      @UI.lineItem: [{ position: 1110 }]
      @EndUserText.label: 'Version'
      VSNMR_V,
 
      @UI.lineItem: [{ position: 1120 }]
      @EndUserText.label: 'Int.ID'
      HANDLE,
 
      @UI.lineItem: [{ position: 1130 }]
      @EndUserText.label: 'DG Mgmt Profile'
      PROLI,
 
      @UI.lineItem: [{ position: 1140 }]
      @EndUserText.label: 'Contains DG'
      CONT_DG,
 
      @UI.lineItem: [{ position: 1150 }]
      @EndUserText.label: 'Char 70'
      CRM_GUID,
 
      @UI.lineItem: [{ position: 1160 }]
      @EndUserText.label: 'Time Stamp'
      UPD_TMSTMP,
 
      @UI.lineItem: [{ position: 1170 }]
      @EndUserText.label: 'Process ID No.'
      MSR_ID,
 
      @UI.lineItem: [{ position: 1180 }]
      @EndUserText.label: 'Control Key'
      TM_CTRL_KEY,
 
      @UI.lineItem: [{ position: 1190 }]
      @EndUserText.label: 'Location ID'
      OIPBL,
 
      @UI.lineItem: [{ position: 1200 }]
      @EndUserText.label: 'Last Changed By'
      LAST_CHANGED_BY_USER,
 
      @UI.lineItem: [{ position: 1210 }]
      @EndUserText.label: 'Handover Location'
      HANDOVERLOC,
 
      @UI.lineItem: [{ position: 1220 }]
      @EndUserText.label: 'Ext. Bus. Syst. ID'
      EXT_BUS_SYST_ID,
 
      @UI.lineItem: [{ position: 1230 }]
      @EndUserText.label: 'External Document ID'
      EXT_REF_DOC_ID,
 
      @UI.lineItem: [{ position: 1240 }]
      @EndUserText.label: 'External Revision'
      EXT_REV_TMSTMP,
 
      @UI.lineItem: [{ position: 1250 }]
      @EndUserText.label: 'Approval Status'
      APM_APPROVAL_STATUS,
 
      @UI.lineItem: [{ position: 1260 }]
      @EndUserText.label: 'Apprvl Req. Rsn ID'
      APM_APPROVAL_REASON,
 
      @UI.lineItem: [{ position: 1270 }]
      @EndUserText.label: 'Apprvl Req Rjcn Rsn'
      APM_REJECTION_REASON,
 
      @UI.lineItem: [{ position: 1280 }]
      @EndUserText.label: 'Solution Order'
      SOLUTION_ORDER_ID,
 
      @UI.lineItem: [{ position: 1290 }]
      @EndUserText.label: 'Comm system Type'
      EXT_COMM_SYST_TYPE,
 
      @UI.lineItem: [{ position: 1300 }]
      @EndUserText.label: 'Purchasing Doc Retro'
      RETRO_PURCHDOC_CREATION,
 
      @UI.lineItem: [{ position: 1310 }]
      @EndUserText.label: 'CrossItemPricingDate'
      CROSSITEM_PRC_DATE,
 
      @UI.lineItem: [{ position: 1320 }]
      @EndUserText.label: 'Data Aging'
      _DATAAGING,
 
      @UI.lineItem: [{ position: 1330 }]
      @EndUserText.label: 'Rejection Sts'
      ABSTK,
 
      @UI.lineItem: [{ position: 1340 }]
      @EndUserText.label: 'Deliv. Conf.Sts'
      BESTK,
 
      @UI.lineItem: [{ position: 1350 }]
      @EndUserText.label: 'Value'
      CMPSC,
 
      @UI.lineItem: [{ position: 1360 }]
      @EndUserText.label: 'TermsOfPayment'
      CMPSD,
 
      @UI.lineItem: [{ position: 1370 }]
      @EndUserText.label: 'Financial Doc.'
      CMPSI,
 
      @UI.lineItem: [{ position: 1380 }]
      @EndUserText.label: 'ExptCreditInsur'
      CMPSJ,
 
      @UI.lineItem: [{ position: 1390 }]
      @EndUserText.label: 'Payment Card'
      CMPSK,
 
      @UI.lineItem: [{ position: 1400 }]
      @EndUserText.label: 'SAP Cred. Mgmt'
      CMPS_CM,
 
      @UI.lineItem: [{ position: 1410 }]
      @EndUserText.label: 'CrMa TE Status'
      CMPS_TE,
 
      @UI.lineItem: [{ position: 1420 }]
      @EndUserText.label: 'OverallCredStat'
      CMGST,
 
      @UI.lineItem: [{ position: 1430 }]
      @EndUserText.label: 'Purg Conf. Sts'
      COSTA,
 
      @UI.lineItem: [{ position: 1440 }]
      @EndUserText.label: 'Delay Status'
      DCSTK,
 
      @UI.lineItem: [{ position: 1450 }]
      @EndUserText.label: 'Ord.Rel.BillgSt'
      FKSAK,
 
      @UI.lineItem: [{ position: 1460 }]
      @EndUserText.label: 'Status Funds Mgmt'
      FMSTK,
 
      @UI.lineItem: [{ position: 1470 }]
      @EndUserText.label: 'Billg Block Sts'
      FSSTK,
 
      @UI.lineItem: [{ position: 1480 }]
      @EndUserText.label: 'Overall Status'
      GBSTK,
 
      @UI.lineItem: [{ position: 1490 }]
      @EndUserText.label: 'Ovrl Deliv. Sts'
      LFGSK,
 
      @UI.lineItem: [{ position: 1500 }]
      @EndUserText.label: 'Delivery Status'
      LFSTK,
 
      @UI.lineItem: [{ position: 1510 }]
      @EndUserText.label: 'OvrlDelivBlkSts'
      LSSTK,
 
      @UI.lineItem: [{ position: 1520 }]
      @EndUserText.label: 'Manual Completion'
      MANEK,
 
      @UI.lineItem: [{ position: 1530 }]
      @EndUserText.label: 'Ovrl Ref. Sts'
      RFGSK,
 
      @UI.lineItem: [{ position: 1540 }]
      @EndUserText.label: 'Reference Sts'
      RFSTK,
 
      @UI.lineItem: [{ position: 1550 }]
      @EndUserText.label: 'Ovrl Block Sts'
      SPSTG,
 
      @UI.lineItem: [{ position: 1560 }]
      @EndUserText.label: 'Transp.Plng Sts'
      TRSTA,
 
      @UI.lineItem: [{ position: 1570 }]
      @EndUserText.label: 'Overall Header'
      UVALL,
 
      @UI.lineItem: [{ position: 1580 }]
      @EndUserText.label: 'All Items'
      UVALS,
 
      @UI.lineItem: [{ position: 1590 }]
      @EndUserText.label: 'Billing – Hdr'
      UVFAK,
 
      @UI.lineItem: [{ position: 1600 }]
      @EndUserText.label: 'Billg–All Items'
      UVFAS,
 
      @UI.lineItem: [{ position: 1610 }]
      @EndUserText.label: 'Prcg – All Itms'
      UVPRS,
 
      @UI.lineItem: [{ position: 1620 }]
      @EndUserText.label: 'Delivery – Hdr'
      UVVLK,
 
      @UI.lineItem: [{ position: 1630 }]
      @EndUserText.label: 'Deliv–All Itms'
      UVVLS,
 
      @UI.lineItem: [{ position: 1640 }]
      @EndUserText.label: 'Hdr reserves 1'
      UVK01,
 
      @UI.lineItem: [{ position: 1650 }]
      @EndUserText.label: 'Hdr reserves 2'
      UVK02,
 
      @UI.lineItem: [{ position: 1660 }]
      @EndUserText.label: 'Hdr reserves 3'
      UVK03,
 
      @UI.lineItem: [{ position: 1670 }]
      @EndUserText.label: 'Hdr reserves 4'
      UVK04,
 
      @UI.lineItem: [{ position: 1680 }]
      @EndUserText.label: 'Hdr reserves 5'
      UVK05,
 
      @UI.lineItem: [{ position: 1690 }]
      @EndUserText.label: 'Total reserves1'
      UVS01,
 
      @UI.lineItem: [{ position: 1700 }]
      @EndUserText.label: 'TotalReserves2'
      UVS02,
 
      @UI.lineItem: [{ position: 1710 }]
      @EndUserText.label: 'Total reserves3'
      UVS03,
 
      @UI.lineItem: [{ position: 1720 }]
      @EndUserText.label: 'Total reserves4'
      UVS04,
 
      @UI.lineItem: [{ position: 1730 }]
      @EndUserText.label: 'Total reserves5'
      UVS05,
 
      @UI.lineItem: [{ position: 1740 }]
      @EndUserText.label: 'Goods Mvmnt Sts'
      WBSTK,
 
      @UI.lineItem: [{ position: 1750 }]
      @EndUserText.label: 'Embargo Status'
      TOTAL_EMCST,
 
      @UI.lineItem: [{ position: 1760 }]
      @EndUserText.label: 'Screening Status'
      TOTAL_SLCST,
 
      @UI.lineItem: [{ position: 1770 }]
      @EndUserText.label: 'Legal Control Status'
      TOTAL_LCCST,
 
      @UI.lineItem: [{ position: 1780 }]
      @EndUserText.label: 'Prod. Marktablty Sts'
      TOTAL_PCSTA,
 
      @UI.lineItem: [{ position: 1790 }]
      @EndUserText.label: 'Dangerous Goods Sts'
      TOTAL_DGSTA,
 
      @UI.lineItem: [{ position: 1800 }]
      @EndUserText.label: 'Sfty Data Sheet Sts'
      TOTAL_SDSSTA,
 
      @UI.lineItem: [{ position: 1810 }]
      @EndUserText.label: 'OmniChnl Sls Pro Sts'
      BOB_STATUS,
 
      @UI.lineItem: [{ position: 1820 }]
      @EndUserText.label: 'Down Payment Status'
      DP_CLEAR_STA_HDR,
 
      @UI.lineItem: [{ position: 1830 }]
      @EndUserText.label: 'B2B Prcessing Status'
      B2B_MSG_PROCESSING_STATUS,
 
      @UI.lineItem: [{ position: 1840 }]
      @EndUserText.label: 'Del.Rel.BillgSt'
      TOTAL_DELIV_RELTD_BILLG_STA,
 
      @UI.lineItem: [{ position: 1850 }]
      @EndUserText.label: 'SDM Versioning'
      SDM_VERSION,
 
      @UI.lineItem: [{ position: 1860 }]
      @EndUserText.label: ''
      DUMMY_SALESDOC_INCL_EEW_PS,
 
      @UI.lineItem: [{ position: 1870 }]
      @EndUserText.label: ''
      ZZ1_TIENNVSALES01_SDH,
 
      @UI.lineItem: [{ position: 1880 }]
      @EndUserText.label: ''
      ZZ1_TIENNVCHECK_SDH,
 
      @UI.lineItem: [{ position: 1890 }]
      @EndUserText.label: ''
      GLO_LOG_REF1_HD,
 
      @UI.lineItem: [{ position: 1900 }]
      @EndUserText.label: 'Deal Number'
      /DMBE/DEALNUMBER,
 
      @UI.lineItem: [{ position: 1910 }]
      @EndUserText.label: 'Renewal Period - EG'
      /DMBE/EVGIDRENEWAL,
 
      @UI.lineItem: [{ position: 1920 }]
      @EndUserText.label: 'Cancellation Period'
      /DMBE/EVGIDCANCEL,
 
      @UI.lineItem: [{ position: 1930 }]
      @EndUserText.label: 'Annexing Package'
      ZAPCGKH,
 
      @UI.lineItem: [{ position: 1940 }]
      @EndUserText.label: 'Ann.Package Extend'
      APCGK_EXTENDH,
 
      @UI.lineItem: [{ position: 1950 }]
      @EndUserText.label: 'Annexing base date'
      ZABDATH,
 
      @UI.lineItem: [{ position: 1960 }]
      @EndUserText.label: 'A&D Bill. Rule'
      AD01FAREG,
 
      @UI.lineItem: [{ position: 1970 }]
      @EndUserText.label: 'Initial Doc.'
      AD01BASDOC,
 
      @UI.lineItem: [{ position: 1980 }]
      @EndUserText.label: 'Last voucher'
      LASTVCHR,
 
      @UI.lineItem: [{ position: 1990 }]
      @EndUserText.label: 'Posting Date'
      PSM_BUDAT,
 
      @UI.lineItem: [{ position: 2000 }]
      @EndUserText.label: 'Customer Grp 6'
      FSH_KVGR6,
 
      @UI.lineItem: [{ position: 2010 }]
      @EndUserText.label: 'Customer Grp 7'
      FSH_KVGR7,
 
      @UI.lineItem: [{ position: 2020 }]
      @EndUserText.label: 'Customer Grp 8'
      FSH_KVGR8,
 
      @UI.lineItem: [{ position: 2030 }]
      @EndUserText.label: 'Customer Grp 9'
      FSH_KVGR9,
 
      @UI.lineItem: [{ position: 2040 }]
      @EndUserText.label: 'Customer Grp 10'
      FSH_KVGR10,
 
      @UI.lineItem: [{ position: 2050 }]
      @EndUserText.label: 'Release Rule'
      FSH_REREG,
 
      @UI.lineItem: [{ position: 2060 }]
      @EndUserText.label: 'Rqmt Relevant'
      FSH_CQ_CHECK,
 
      @UI.lineItem: [{ position: 2070 }]
      @EndUserText.label: 'Snap. Status'
      FSH_VRSN_STATUS,
 
      @UI.lineItem: [{ position: 2080 }]
      @EndUserText.label: 'Transaction Number'
      FSH_TRANSACTION,
 
      @UI.lineItem: [{ position: 2090 }]
      @EndUserText.label: 'VAS Cust. Group'
      FSH_VAS_CG,
 
      @UI.lineItem: [{ position: 2100 }]
      @EndUserText.label: 'Cancel Date'
      FSH_CANDATE,
 
      @UI.lineItem: [{ position: 2110 }]
      @EndUserText.label: 'Sched. Strat.'
      FSH_SS,
 
      @UI.lineItem: [{ position: 2120 }]
      @EndUserText.label: 'Changed Manually'
      FSH_OS_STG_CHANGE,
 
      @UI.lineItem: [{ position: 2130 }]
      @EndUserText.label: 'ETM-Rel. Ind.'
      J_3GKBAUL,
 
      @UI.lineItem: [{ position: 2140 }]
      @EndUserText.label: 'Application ID'
      MILL_APPL_ID,
 
      @UI.lineItem: [{ position: 2150 }]
      @EndUserText.label: 'Treasury Account Sym'
      TAS,
 
      @UI.lineItem: [{ position: 2160 }]
      @EndUserText.label: 'Business Evt Typ Cd'
      BETC,
 
      @UI.lineItem: [{ position: 2170 }]
      @EndUserText.label: 'Modification Allowed'
      MOD_ALLOW,
 
      @UI.lineItem: [{ position: 2180 }]
      @EndUserText.label: 'Cancellation Allowed'
      CANCEL_ALLOW,
 
      @UI.lineItem: [{ position: 2190 }]
      @EndUserText.label: 'Payment Methods'
      PAY_METHOD,
 
      @UI.lineItem: [{ position: 2200 }]
      @EndUserText.label: 'Business Partner No.'
      BPN,
 
      @UI.lineItem: [{ position: 2210 }]
      @EndUserText.label: 'Reporting Frequency'
      REP_FREQ,
 
      @UI.lineItem: [{ position: 2220 }]
      @EndUserText.label: 'Logical system'
      LOGSYSB,
 
      @UI.lineItem: [{ position: 2230 }]
      @EndUserText.label: 'Proc. Camp.Det.'
      KALCD,
 
      @UI.lineItem: [{ position: 2240 }]
      @EndUserText.label: 'Multiple Promotions'
      MULTI,
 
      @UI.lineItem: [{ position: 2250 }]
      @EndUserText.label: 'PaymMethod'
      SPPAYM,
 
      @UI.lineItem: [{ position: 2260 }]
      @EndUserText.label: 'Claim Header'
      WTYSC_CLM_HDR,
 
      @UI.lineItem: [{ position: 2270 }]
      @EndUserText.label: 'Sign. Status'
      ZZ_SIGN_STATUS,
 
      @UI.lineItem: [{ position: 2280 }]
      @EndUserText.label: 'Agreem. ID'
      ZZ_AGREEMENT_ID,
 
      @UI.lineItem: [{ position: 2290 }]
      @EndUserText.label: 'Agr. Send D.'
      ZZ_SEND_DATE,
 
      @UI.lineItem: [{ position: 2300 }]
      @EndUserText.label: 'Agr. Sen. T.'
      ZZ_SEND_TIME,
 
      @UI.lineItem: [{ position: 2310 }]
      @EndUserText.label: 'Agr. Sig. D.'
      ZZ_SIGN_DATE,
 
      @UI.lineItem: [{ position: 2320 }]
      @EndUserText.label: 'Agr. Sig. T.'
      ZZ_SIGN_TIME,
 
      @UI.lineItem: [{ position: 2330 }]
      @EndUserText.label: 'reg. no.'
      ZZREGNUM,
 
      @UI.lineItem: [{ position: 2340 }]
      @EndUserText.label: 'reg. dt'
      ZZREGDT,
 
      @UI.lineItem: [{ position: 2350 }]
      @EndUserText.label: 'reg. off'
      ZZREGOFFICE
}

REPORT ztest_export_multi_value_demo.

" (1) SELECT liệt kê rõ nhiều field (khong dung *) -> ky vong
"     SelectedFields cua section DB_OBJ = "MATNR MTART MATKL"
SELECT matnr, mtart, matkl
  FROM mara
  INTO TABLE @DATA(lt_result)
  WHERE matnr = 'TEST123'.

" (2) JOIN 2 bang -> ky vong JoinedObjects = "MARA, MARC"
SELECT a~matnr, a~mtart, b~werks, b~beskz
  FROM mara AS a
  INNER JOIN marc AS b ON a~matnr = b~matnr
  INTO TABLE @DATA(lt_joined)
  WHERE a~matnr = 'TEST123'.

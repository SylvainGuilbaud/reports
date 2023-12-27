from spire.xls import *
from spire.xls.common import *

#Create a workbook
workbook = Workbook()
#Load an Excel XLS or XLSX file
workbook.LoadFromFile("Sample.xlsx")

#Fit each worksheet to one page
workbook.ConverterSetting.SheetFitToPage = True
#convert the Excel file to PDF format
workbook.SaveToFile("ExcelToPDF.pdf", FileFormat.PDF)
workbook.Dispose()
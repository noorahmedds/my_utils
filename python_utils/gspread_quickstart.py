# Find the rest of the details for setup here: https://docs.gspread.org/en/latest/oauth2.html

import gspread

gc = gspread.service_account()

sh = gc.open("Example spreadsheet")

print(sh.sheet1.get('A1'))

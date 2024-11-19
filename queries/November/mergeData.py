import pandas as pd

# Load the CSV files
# Replace with the actual path to your first file
file1 = pd.read_csv('queries/November/merged_file.csv')
file2 = pd.read_csv('queries/November/dataGsheetsAll.csv')
file2['shop_id'] = file2['shop_id'].apply(lambda x: int(
    x[3:]) if isinstance(x, str) and len(x) > 3 else x)

resultado = file1.merge(
    file2[['shop_id', 'BD', 'BDM', 'BDL', 'real_priority']], on='shop_id', how='left')

resultado.to_csv("queries/November/total.csv", index=False)

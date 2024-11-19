import pandas as pd

# Load the CSV files
# Replace with the actual path to your first file
file1 = pd.read_csv('queries/November/dataQuery.csv')
file2 = pd.read_csv('queries/November/dataGsheets.csv')
# Replace with the actual path to your second file

# Group by 'shop_id' and sum up 'complete_order_num_sum' for each 'shop_id'
shop_order_sum = file1.groupby(
    'shop_id')['complete_order_num_sum'].sum().reset_index()
shop_order_sum = shop_order_sum.sort_values(
    by='shop_id').reset_index(drop=True)

file2 = file2[['shop_id', 'completed_order']]
file2 = file2.sort_values(
    by='shop_id').reset_index(drop=True)

file2['shop_id'] = file2['shop_id'].apply(lambda x: int(
    x[3:]) if isinstance(x, str) and len(x) > 3 else x)
# Check if each 'shop_id' in file2 exists in shop_order_sum
file2['exists_in_file1'] = file2['shop_id'].isin(shop_order_sum['shop_id'])

# Apply transformation to 'shop_id' in file2

merged_df = pd.merge(file2, shop_order_sum, on='shop_id', how='left')

# Check if each 'shop_id' in file2 exists in file1 and if orders match
merged_df['exists_in_file1'] = merged_df['complete_order_num_sum'].notna()
merged_df['orders_match'] = merged_df['completed_order'] == merged_df['complete_order_num_sum']

# View the results
print(merged_df[['shop_id', 'completed_order',
      'complete_order_num_sum', 'exists_in_file1', 'orders_match']])

print(merged_df[merged_df['orders_match'] == False])
print(sum(merged_df['completed_order']))

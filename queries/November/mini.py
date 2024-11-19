import pandas as pd

# Cargar el archivo CSV
df = pd.read_csv('queries/November/total.csv')

# Convertir la columna 'date_data' a tipo datetime para asegurar un orden correcto
df['date_data'] = pd.to_datetime(df['date_data'])

# Ordenar primero por 'shop_id' y luego por 'date_data'
df_sorted = df.sort_values(by=['shop_id', 'date_data'])

# Guardar el archivo ordenado
df_sorted.to_csv('queries/November/total_sorted.csv', index=False)

# Mostrar el DataFrame ordenado
print(df_sorted)

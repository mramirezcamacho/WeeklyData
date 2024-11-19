import pandas as pd

# Cargar datos y reemplazar '-' con 0
data = pd.read_csv('queries/November/weeklyDataAugust2OctCKA.csv')
data['Daily Orders'] = pd.to_numeric(data['Daily Orders'].replace('-', 0))

# Crear una columna de 'Mes' basada en 'stat_date(周)'


def get_month(week):
    if week in ['2024-07-29 / 2024-08-04', '2024-08-05 / 2024-08-11', '2024-08-12 / 2024-08-18',
                '2024-08-19 / 2024-08-25', '2024-08-26 / 2024-09-01']:
        return 'Agosto'
    elif week in ['2024-09-02 / 2024-09-08', '2024-09-09 / 2024-09-15', '2024-09-16 / 2024-09-22',
                  '2024-09-23 / 2024-09-29']:
        return 'Septiembre'
    else:
        return 'Octubre'


data['Mes'] = data['stat_date(周)'].apply(get_month)

# Crear un diccionario para almacenar los DataFrames de cada país
country_dfs = {}

# Iterar por cada país
for country, country_data in data.groupby('Country'):
    # Obtener el promedio de 'Daily Orders' por ciudad y mes
    avg_monthly_city = country_data.groupby(['city_name', 'Mes'])[
        'Daily Orders'].mean().unstack(fill_value=0)

    # Calcular MoM y Mo2M porcentuales
    avg_monthly_city['MoM (%)'] = ((avg_monthly_city['Octubre'] -
                                    avg_monthly_city['Septiembre']) / avg_monthly_city['Septiembre']) * 100
    avg_monthly_city['Mo2M (%)'] = ((avg_monthly_city['Octubre'] -
                                     avg_monthly_city['Agosto']) / avg_monthly_city['Agosto']) * 100

    # Calcular MoM y Mo2M nominales
    avg_monthly_city['MoM (nominal)'] = avg_monthly_city['Octubre'] - \
        avg_monthly_city['Septiembre']
    avg_monthly_city['Mo2M (nominal)'] = avg_monthly_city['Octubre'] - \
        avg_monthly_city['Agosto']

    # Reemplazar valores infinitos o NaN en caso de divisiones por cero
    avg_monthly_city.replace([float('inf'), -float('inf')], 0, inplace=True)
    avg_monthly_city.fillna(0, inplace=True)

    # Guardar el DataFrame resultante en el diccionario
    country_dfs[country] = avg_monthly_city

    # Encontrar el máximo de cada columna para MoM y Mo2M tanto nominal como porcentual
    mom_nominal_max = avg_monthly_city['MoM (nominal)'].idxmax()
    mom_percentage_max = avg_monthly_city['MoM (%)'].idxmax()
    mo2m_nominal_max = avg_monthly_city['Mo2M (nominal)'].idxmax()
    mo2m_percentage_max = avg_monthly_city['Mo2M (%)'].idxmax()

    # Imprimir resultados
    print(f"\nPara el país {country}:")
    print(f"- La ciudad con mayor crecimiento MoM nominal es {mom_nominal_max}, con un aumento de {
          avg_monthly_city.loc[mom_nominal_max, 'MoM (nominal)']}")
    print(f"- La ciudad con mayor crecimiento MoM porcentual es {
          mom_percentage_max}, con un aumento de {avg_monthly_city.loc[mom_percentage_max, 'MoM (%)']}%")
    print(f"- La ciudad con mayor crecimiento Mo2M nominal es {mo2m_nominal_max}, con un aumento de {
          avg_monthly_city.loc[mo2m_nominal_max, 'Mo2M (nominal)']}")
    print(f"- La ciudad con mayor crecimiento Mo2M porcentual es {
          mo2m_percentage_max}, con un aumento de {avg_monthly_city.loc[mo2m_percentage_max, 'Mo2M (%)']}%")

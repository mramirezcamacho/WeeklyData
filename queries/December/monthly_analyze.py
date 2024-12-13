import pandas as pd

# Cargar datos y reemplazar '-' con 0
data = pd.read_csv('queries/December/weeklyDataAugust2OctCKA.csv')
data['Daily Orders'] = pd.to_numeric(data['Daily Orders'].replace('-', 0))
LM, LM1, LM2 = 'Noviembre', 'Octubre', 'Septiembre'
# Crear una columna de 'Mes' basada en 'stat_date(周)'


def get_month(week):
    if week in [
        '2024-09-02 / 2024-09-08', '2024-09-09 / 2024-09-15',
        '2024-09-16 / 2024-09-22', '2024-09-23 / 2024-09-29'
    ]:
        return 'Septiembre'
    elif week in [
        '2024-09-30 / 2024-10-06', '2024-10-07 / 2024-10-13',
        '2024-10-14 / 2024-10-20', '2024-10-21 / 2024-10-27',
        '2024-10-28 / 2024-11-03'
    ]:
        return 'Octubre'
    elif week in [
        '2024-11-04 / 2024-11-10', '2024-11-11 / 2024-11-17',
        '2024-11-18 / 2024-11-24', '2024-11-25 / 2024-12-01'
    ]:
        return 'Noviembre'
    else:
        print('-'*20)
        print('¡Esto no debería pasar!')
        print('-'*20)
        return 'Mes desconocido'


data['Mes'] = data['stat_date(周)'].apply(get_month)

# Crear un diccionario para almacenar los DataFrames de cada país
country_dfs = {}

# Iterar por cada país
for country, country_data in data.groupby('Country'):
    # Obtener el promedio de 'Daily Orders' por ciudad y mes
    avg_monthly_city = country_data.groupby(['city_name', 'Mes'])[
        'Daily Orders'].mean().unstack(fill_value=0)

    # Calcular MoM y Mo2M porcentuales
    avg_monthly_city['MoM (%)'] = round(((avg_monthly_city[LM] -
                                          avg_monthly_city[LM1]) / avg_monthly_city[LM1]) * 100, 2)
    avg_monthly_city['Mo2M (%)'] = round(((avg_monthly_city[LM] -
                                           avg_monthly_city[LM2]) / avg_monthly_city[LM2]) * 100, 2)

    # Calcular MoM y Mo2M nominales
    avg_monthly_city['MoM (nominal)'] = avg_monthly_city[LM] - \
        avg_monthly_city[LM1]
    avg_monthly_city['Mo2M (nominal)'] = avg_monthly_city[LM] - \
        avg_monthly_city[LM2]

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

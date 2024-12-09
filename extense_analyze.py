import os
from pprint import pprint
import pandas as pd

# Load CSV

dataIfPercentage = {
    "Daily Orders": False,
    "AOP": False,
    "ASP": False,
    "Avg Delivery Fee": False,
    "R Burn / GMV": True,
    "B2C / GMV": True,
    "P2C / GMV": True,
    "TED / GMV": True,
    "Traffic": False,
    "Shop Enter UV": False,
    "B P1": True,
    "B P2": True,
    "B P1*P2": True,
    "B Cancel Rate": True,
    "B Bad Rating Rate": True,
    '5 + order store count(week total)': False
}


def get_all_files_in_folder(folder_path):
    try:
        # List all files in the directory
        files = [f for f in os.listdir(folder_path) if os.path.isfile(
            os.path.join(folder_path, f))]
        return files
    except Exception as e:
        print(f"An error occurred: {e}")
        return []


def getData(file='CKA/CKAWeekly2', percentage=True, columnOfInterest='R Burn / GMV', vertical='CKA'):
    df = pd.read_csv(file)
    if 'organization_type' in df.columns:
        if ('CKA' != vertical):
            if (vertical not in list(df['organization_type'].values)):
                vertical_text = 'Normal' if 'SME' == vertical else 'SME'
            else:
                vertical_text = vertical
        else:
            vertical_text = 'CKA'
        df = df[df['organization_type'] == vertical_text]
    options = ['Date(周)', 'stat_date(周)', 'Stat Date(周)', 'stat_date(周)']
    statVariable = None
    for option in options:
        try:
            weeks = sorted(list(df[option].unique()))[::-1]
            statVariable = option
        except:
            pass
        if statVariable is not None:
            break

    try:
        countries = df['Country Code'].unique()
    except:
        countries = df['country_code'].unique()

    df[columnOfInterest] = df[columnOfInterest].replace('-', '0')

    generalData = {}

    # Process each country
    for country in countries:
        try:
            countryDF = df[df['Country Code'] == country]
        except:
            countryDF = df[df['country_code'] == country]
        cities = countryDF['city_name'].unique()
        dataPerCountry = {}

        # Process each city
        for city in cities:
            cityDF = countryDF[countryDF['city_name'] == city]
            if len(cityDF) < 3:
                continue

            # Get daily orders for the last three weeks
            if percentage:
                week1 = cityDF[cityDF[statVariable] ==
                               weeks[0]][columnOfInterest].values[0]
                week1 = float(week1.replace('%', ''))/100
                week2 = cityDF[cityDF[statVariable] ==
                               weeks[1]][columnOfInterest].values[0]
                week2 = float(week2.replace('%', ''))/100
                week3 = cityDF[cityDF[statVariable] ==
                               weeks[2]][columnOfInterest].values[0]
                week3 = float(week3.replace('%', ''))/100
            else:
                week1 = float(cityDF[cityDF[statVariable] ==
                                     weeks[0]][columnOfInterest].values[0])
                week2 = float(cityDF[cityDF[statVariable] ==
                                     weeks[1]][columnOfInterest].values[0])
                week3 = float(cityDF[cityDF[statVariable] ==
                                     weeks[2]][columnOfInterest].values[0])

            # Calculate WoW and Wo2W and handle exceptions
            try:
                WoW = (week1 - week2) / week2 if week2 != 0 else None
            except:
                WoW = None
            try:
                Wo2W = (week1 - week3) / week3 if week3 != 0 else None
            except:
                Wo2W = None

            # Calculate nominal changes
            nominalWoW = week1 - week2
            nominalWo2W = week1 - week3

            # Store data for each city
            if not ((week1 - week2 == 0) and (week1 - week3 == 0) and (WoW is None) and (Wo2W is None)) and not ((WoW is None) or (Wo2W is None)):
                dataPerCountry[city] = {
                    'WoW': WoW,
                    'Wo2W': Wo2W,
                    'nominalWoW': nominalWoW,
                    'nominalWo2W': nominalWo2W
                }

        # Sort cities by each characteristic in descending order
        sortedByWoW = sorted(dataPerCountry.items(), key=lambda x: (
            x[1]['WoW'] is None, x[1]['WoW']), reverse=True)
        sortedByWo2W = sorted(dataPerCountry.items(), key=lambda x: (
            x[1]['Wo2W'] is None, x[1]['Wo2W']), reverse=True)
        sortedByNominalWoW = sorted(dataPerCountry.items(
        ), key=lambda x: x[1]['nominalWoW'], reverse=True)
        sortedByNominalWo2W = sorted(dataPerCountry.items(
        ), key=lambda x: x[1]['nominalWo2W'], reverse=True)

        # Add sorted data to the general dictionary
        generalData[country] = {
            'sortedByWoW': sortedByWoW,
            'sortedByWo2W': sortedByWo2W,
            'sortedByNominalWoW': sortedByNominalWoW,
            'sortedByNominalWo2W': sortedByNominalWo2W
        }
    return generalData


def getDataRefined(metricParameter: str = None, vertical: str = 'CKA'):
    percentage = dataIfPercentage[metricParameter]
    files = get_all_files_in_folder("weeklyData")
    ready = False
    for filePath in files:
        try:
            data = getData(file=f'weeklyData/{filePath}', percentage=percentage,
                           columnOfInterest=metricParameter, vertical=vertical)
            ready = True
        except Exception as e:
            # print(filePath)
            # print(e)
            pass
        if ready:
            break
    if not ready:
        raise ValueError
    return data


def showData(onlyAColumn: str = None, metricParameter: str = None, all=False):
    data = getDataRefined(metricParameter, VERTICAL)

    for country, values in data.items():
        if all or (country in ['MX', 'CO']):
            print(f'For the country {country} this are the stats')
            for metric, listCities in values.items():
                metric = metric.replace('sortedBy', '')
                if (onlyAColumn is None) or (onlyAColumn.lower() == metric.lower()):
                    print(f'In the metric {metric} the best are:')
                    best = listCities[:3]
                    for city in best:
                        print(f'The city {city[0]} stats are:')
                        showNicely(city[1], dataIfPercentage[metricParameter])
                    print(f'In the metric {metric} the worse are:')
                    worse = listCities[-3:]
                    for city in worse:
                        print(f'The city {city[0]} stats are:')
                        showNicely(city[1], dataIfPercentage[metricParameter])
                    print('\n')
            print('\n')


def showNicely(data: dict, percentage: bool):
    for timeMetric, number in data.items():
        if timeMetric in ('WoW', 'Wo2W') or percentage:
            print(f'\t{timeMetric}: {round(number*100, 2)}%')
        else:
            print(f'\t{timeMetric}: {round(number, 2)}')


def showDataCity(metricParameter: str = None, city: str = None):
    data = getDataRefined(metricParameter, VERTICAL)

    for country, values in data.items():
        print(f'For the country {country} this are the stats')
        for metric, listCities in values.items():
            metric = metric.replace('sortedBy', '')
            for cityData in listCities:
                if cityData[0].lower() == city.lower():
                    print(f'The city {cityData[0]} stats are:')
                    showNicely(cityData[1], dataIfPercentage[metricParameter])
                    return
        print('\n')


'''
Daily Orders

R Burn / GMV
B2C / GMV
P2C / GMV
TED / GMV

Traffic
Shop Enter UV
B P1
B P2
B P1*P2
B Cancel Rate
B Bad Rating Rate

5 + order store count(week total)

AOP
ASP
Avg Delivery Fee
"""

"""
WoW
Wo2W
NominalWoW
NominalWo2W
'''

general, specific = 0, 1

column = 'Avg Delivery Fee'
column = 'Shop Enter UV'
column = 'B P1*P2'
column = 'R Burn / GMV'
column = 'Traffic'
column = 'TED / GMV'
column = '5 + order store count(week total)'
column = 'Daily Orders'
column = 'ASP'
column = 'B2C / GMV'
column = 'B Cancel Rate'


city = 'Mexico City'
city = 'Guadalajara'
city = 'Monterrey'
city = 'Bogotá, D.C.'
city = 'Medellín'

metric = 'NominalWo2W'

VERTICAL = 'SME'
VERTICAL = 'CKA'
ALL = 0
if __name__ == "__main__":
    if general:
        print(f'Using the column {column}:')
        showData(metric, column, all=ALL)
    if specific:
        print(f'Using the column {column}:')
        showDataCity(column,  city)

# pprint(getDataRefined(column, dataIfPercentage[column]))

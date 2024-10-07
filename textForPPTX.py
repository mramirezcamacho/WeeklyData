from main import *
import random


def prettyNames(metric):
    return metric.replace('B ', '').replace(' / GMV', '').replace('*', '')


def mostAffectedMetric(positive: bool, cities: list[str], country):
    possibleResponsables = [
        "R Burn / GMV",
        "B2C / GMV",
        "TED / GMV",
        "Traffic",
        "B P1*P2",
    ]
    biggestResponsable = []
    for _ in range(len(cities)):
        biggestResponsable.append(["", 0, 0])
    for i, responsable in enumerate(possibleResponsables):
        percentage = dataIfPercentage[responsable]
        miniData = getDataRefined(responsable)
        for j, city in enumerate(cities):
            for cityDict, dataDict in miniData[country]['sortedByNominalWo2W']:
                if cityDict == city:
                    if positive:
                        if biggestResponsable[j][1] < dataDict['Wo2W']:
                            biggestResponsable[j][0] = responsable
                            biggestResponsable[j][1] = dataDict['Wo2W']
                            biggestResponsable[j][2] = dataDict['nominalWo2W']
                            if percentage:
                                biggestResponsable[j][2] = str(round(
                                    (biggestResponsable[j][2]*100), 2))+'pp'
                    else:
                        if biggestResponsable[j][1] > dataDict['Wo2W']:
                            biggestResponsable[j][0] = responsable
                            biggestResponsable[j][1] = dataDict['Wo2W']
                            biggestResponsable[j][2] = dataDict['nominalWo2W']
                            if percentage:
                                biggestResponsable[j][2] = str(round(
                                    (biggestResponsable[j][2]*100), 2))+'pp'
    return biggestResponsable


def joinCities(cities: list, separadorFinal: str = '&'):
    if len(cities) == 1:
        result = cities[0]
    elif len(cities) == 2:
        result = f' {separadorFinal} '.join(cities)
    else:
        result = ', '.join(cities[:-1]) + f' {separadorFinal} ' + cities[-1]
    return result


def getTextCities():
    data = getDataRefined('Daily Orders')
    citiesPerCountry = {
        'MX': ['Mexico City',
               'Monterrey',
               'Guadalajara',],
        'CO': ['Bogotá, D.C.',
               'Medellín',]
    }
    diminutivo = {
        'Mexico City': 'CDMX',
        'Monterrey': 'MTY',
        'Guadalajara': 'GDL',
        'Medellín': 'MED',
        'Bogotá, D.C.': 'BOG',
    }
    refinedData = []
    for country in citiesPerCountry.keys():
        cities = citiesPerCountry[country]
        for city in cities:
            realPositive = 0
            positive = 1
            for cityDict, cityDictData in data[country]['sortedByNominalWo2W']:
                if cityDict == city and cityDictData['Wo2W'] < 0:
                    positive = 0
                if cityDict == city and cityDictData['Wo2W'] < -0.01:
                    realPositive = -1
                if cityDict == city and cityDictData['Wo2W'] > 0.01:
                    realPositive = 1

            detailData = mostAffectedMetric(positive, [city], country)
            refinedData.append((city, realPositive, detailData[0]))

    clusters = {}
    positiveStr = ['Boost', 'Improvement'][random.randint(0, 1)]
    negativeStr = ['Decline', 'Decrease'][random.randint(0, 1)]
    for generalCityData in refinedData:
        city, realPositive, detailData = generalCityData
        key = ''
        if realPositive == 1:
            key = positiveStr
        if realPositive == -1:
            key = negativeStr
        if realPositive == 0:
            key = 'Stable'
        if key not in clusters:
            clusters[key] = []
        clusters[key].append((city, detailData))

    for cluster, listCitiesData in clusters.items():
        cities = [diminutivo[cityData[0]] for cityData in listCitiesData]
        stringText = f'- {joinCities(cities)}: {cluster} Wo2W'
        if cluster != 'Stable':
            stringText += f' ' + ['mainly due the', 'mostly due the',
                                  'because of the'][random.randint(0, 2)] + ' '
            if len(listCitiesData) == 1:
                positive = 1 if listCitiesData[0][1][1] > 0 else 0
                adjetive = ''
                if positive:
                    adjetive = ['Growth', 'Rise',
                                'Spike'][random.randint(0, 2)]
                else:
                    adjetive = ['Drop', 'Reduction',
                                'Fall'][random.randint(0, 2)]
                adjetive = adjetive.lower() + f''' in {prettyNames(listCitiesData[0][1][0])} of {
                    '+' if listCitiesData[0][1][1] > 0 else ''}{round(listCitiesData[0][1][1]*100, 2)}%'''
                if 'pp' in str(listCitiesData[0][1][2]):
                    adjetive += f' ({listCitiesData[0][1][2]})'
                adjetive += '.'
                stringText += adjetive + ' [on/off] target.'
            else:
                positive = 1 if listCitiesData[0][1][1] > 0 else 0
                adjetive = ''
                if positive:
                    adjetive = ['Growth', 'Rise',
                                'Spike'][random.randint(0, 2)] + ' in '
                else:
                    adjetive = ['Drop', 'Reduction',
                                'Fall'][random.randint(0, 2)] + ' in '
                adjetive = adjetive.lower()

                text2append = []
                for cityName, cityDataSingular in listCitiesData:
                    bestString = f'''{prettyNames(cityDataSingular[0])} of {
                        '+' if cityDataSingular[1] > 0 else ''}{round(cityDataSingular[1]*100, 2)}%{f' ({cityDataSingular[2]})' if 'pp' in str(cityDataSingular[2]) else ''} in {diminutivo[cityName]}'''
                    text2append.append(bestString)

                adjetive += joinCities(text2append, ', and')+'.'
                stringText += adjetive
        else:
            stringText += '. [on/off] target.'

        print(stringText)


def getText(metric: str, aditionalText: bool):
    numberOfSuspects = 2
    metricParameter = metric
    data = getDataRefined(metricParameter)
    countries = ['MX', 'CO', 'PE', 'CR']
    for country in countries:
        sortedData = data[country]['sortedByNominalWo2W']
        countryChange = 0
        for city, detailData in sortedData:
            countryChange += detailData['nominalWo2W']
        better = 1 if countryChange > 0 else 0
        if better:
            suspects = sortedData[:numberOfSuspects]
        else:
            suspects = sortedData[-numberOfSuspects:]
            suspects = suspects[::-1]
        randomInt = random.randint(0, 1)

        if country in ('MX', 'CO'):
            str1 = f'''- {country}: {
                'Better' if better else 'Worse'} Wo2W, mainly due '''
            str2 = f'''- {country}: Wo2W {'growth' if better else 'dropped'}, {
                'mostly thanks to' if better else 'mostly due to declines in'} '''
        else:
            str1 = f'''- {country}: {
                'Better' if better else 'Worse'} Wo2W, mainly due '''
            str2 = f'''- {country}: Wo2W {'growth' if better else 'dropped'}, {
                'mostly thanks to' if better else 'mostly due to'} '''
        bestString = [str1, str2][randomInt]
        i = 1
        if country in ('MX', 'CO'):
            for city, detailData in suspects:
                bestString += f'''{city} ({'+' if detailData['nominalWo2W'] > 0 else ''}{
                    round(detailData['nominalWo2W'])})'''

                if i == len(suspects)-2:
                    bestString += ', '
                if i == len(suspects)-1:
                    bestString += ', and '
                elif i == len(suspects):
                    bestString += '. '
                i += 1
        index = 1
        cities = [suspect[0] for suspect in suspects]
        reasons = mostAffectedMetric(better, cities, country)
        if aditionalText:
            if country in ('MX', 'CO'):
                bestString += 'Where '
                randomInt = random.randint(0, 1)
                for i, reason in enumerate(reasons):
                    metric, percentage, nominal = reason
                    metric = prettyNames(metric)
                    bestString += f'''{cities[i]} {['saw', 'had'][randomInt]} a {'drop' if percentage < 0 else 'increase'} in {
                        metric} of {'+' if percentage > 0 else ''}{round(percentage*100, 2)}%'''
                    if 'pp' in str(nominal):
                        bestString += f'({nominal})'
                    if index == len(suspects)-2:
                        bestString += ', '
                    elif index == len(suspects)-1:
                        bestString += ', and '
                    elif index == len(suspects):
                        bestString += '. '
                    index += 1
            else:
                for i, reason in enumerate(reasons):
                    metric, percentage, nominal = reason
                    metric = prettyNames(metric)
                    bestString += f'''a {'drop' if percentage < 0 else 'increase'} in {
                        metric} of {'+' if percentage > 0 else ''}{round(percentage*100, 2)}%'''
                    if 'pp' in str(nominal):
                        bestString += f'({nominal})'
                    if index == len(suspects)-2:
                        bestString += ', '
                    elif index == len(suspects)-1:
                        bestString += ', and '
                    elif index == len(suspects):
                        bestString += '. '
                    index += 1
        else:
            if country in ('PE', 'CR'):
                bestString = bestString.split(', ')[0]+', [on/off] target.'
        print(bestString)


if __name__ == "__main__":
    print('Daily Orders')
    getText('Daily Orders', True)
    print('5 + order store count(week total)')
    getText('5 + order store count(week total)', False)
    print('Cities')
    getTextCities()

'''
if need to update goals

daily orders: https://docs.google.com/spreadsheets/d/1P-XZJ16iyRfltzTNRMqPLLL29BTCd_Vw7FYUWeYD6aM/edit?gid=627266180#gid=627266180

everything else: https://docs.google.com/spreadsheets/d/1P-XZJ16iyRfltzTNRMqPLLL29BTCd_Vw7FYUWeYD6aM/edit?gid=627266180#gid=627266180

'''

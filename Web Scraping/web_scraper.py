# Required Libraries
import os
import requests
from lxml import etree


from bs4 import BeautifulSoup
import pandas as pd
import datetime

def scrape_data():
    """
    Function to Scrape Coronavirus 19 data from the Web and save it in a csv file.
    """
    
    # Required Data Fields
    country = []
    total_cases = []
    new_cases = []
    total_deaths = []
    new_deaths = []
    total_recovered = []
    new_recovered = []
    active_cases = []
    serious_cases = []
    total_cases_per_million = []
    deaths_per_million = []
    total_tests = []
    tests_per_million = []
    population = []

    # Add Today Date
    today = datetime.date.today().strftime("%B %d, %Y")

    URL = 'https://www.worldometers.info/coronavirus/'
    content = requests.get(URL)
    soup = BeautifulSoup(content.text, 'html.parser')
    #Writing to File
    file1 = open("MyFile.txt","a")
    file1.write(soup.prettify())
    file1.close()

    # Find the Required Table
    content_table  = soup.find('table', { "id" : "main_table_countries_today"}) # Use dictionary to pass key : value pair

    # Find the Required Sub-table
    sub_table = content_table.find_all('tbody')[0]
        
    # Find Rows of Sub-table
    rows = sub_table.find_all('tr')
    # Loop through Row entries
    for row in rows:
        content = row.find_all('td')  
        
        # Loop through Row structure    
        if content[1].text.strip() == '':
            continue
        country.append(content[1].text.strip()) # Adding Countries to List
        total_cases.append(content[2].text.strip()) # Adding Total Cases to List
        new_cases.append(content[3].text.strip()) # Adding New Cases to List
        total_deaths.append(content[4].text.strip())
        new_deaths.append(content[5].text.strip())
        total_recovered.append(content[6].text.strip())
        new_recovered.append(content[7].text.strip())
        active_cases.append(content[8].text.strip())
        serious_cases.append(content[9].text.strip())
        total_cases_per_million.append(content[10].text.strip())
        deaths_per_million.append(content[11].text.strip())
        total_tests.append(content[12].text.strip())
        tests_per_million.append(content[13].text.strip())
        population.append(content[14].text.strip())

        
        
    ### Construct Dataframe ###
    data = {'Country':country,'Total Cases':total_cases, 'New Cases':new_cases, 'Total Deaths':total_deaths, 'New Deaths':new_deaths,
            'Total Recovered':total_recovered, 'New_Recovered':new_recovered, 'Active Cases':active_cases, 'Serious/Critical Cases':serious_cases,
            'Total Cases per million':total_cases_per_million, 'Deaths per million':deaths_per_million, 'Total Tests':total_tests,
            'Tests per million':tests_per_million, 'Population':population}
    df = pd.DataFrame(data)

    ### Save Data ###

    # Create New Datafile    
    filename =  str(today) + '.csv'
    if os.path.isfile(filename):
        print('File Exists. Going to overwrite.')
        # Writing Data to csv file
        df.to_csv(filename, index = False, header=True)
    else:
        # Writing Data to csv file
        df.to_csv(filename, index = False, header=True)
    
if __name__ == '__main__':
    scrape_data()



            


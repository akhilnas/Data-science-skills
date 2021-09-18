import selenium
import os
import requests
from lxml import etree
import wget

from bs4 import BeautifulSoup
import pandas as pd
import datetime
import plotly.express as px
import plotly.graph_objects as go

# Read In Old Data
if os.path.exists("/home/akhil/PycharmProjects/Coronavirus/export_dataframe.csv"):
    olddata = pd.read_csv("/home/akhil/PycharmProjects/Coronavirus/export_dataframe.csv")

# List Creator of Required Data Fields
Country = []
Total_Cases = []
New_Cases = []
Total_Deaths = []
New_Deaths = []
Day = []

# Add Today Date
today = datetime.date.today().strftime("%B %d, %Y")
Day.append(today)

URL = 'https://www.worldometers.info/coronavirus/'
content = requests.get(URL)
soup = BeautifulSoup(content.text, 'html.parser')
#Writing to File
file1 = open("MyFile.txt","a")
file1.write(soup.prettify())
file1.close()

contentTable  = soup.find('table', { "id" : "main_table_countries_today"}) # Use dictionary to pass key : value pair
rows  = contentTable.find_all('td')

# Indexer
i = 0
for row in rows:
    i = i + 1
    line = row.get_text()
    if line == '':
        line = 0
    if i%10 == 1:
        Country.append(line)
    elif i%10 == 2:
        Total_Cases.append(line)
    elif i%10 == 3:
        New_Cases.append(line)
    elif i%10 == 4:
        Total_Deaths.append(line)
    elif i%10 == 5:
        New_Deaths.append(line)

# Update List
Day = Day * len(Country)
# Creating Data Frames for Plotting
data = {'Date':Day, 'Country':Country,'Total Cases':Total_Cases,'New Cases':New_Cases,'Total Deaths':Total_Deaths,'New_Deaths':New_Deaths}
df = pd.DataFrame(data)
df.drop(df.tail(1).index,inplace=True) # drop last n rows

# Append Data to Old Data
if os.path.exists("/home/akhil/PycharmProjects/Coronavirus/export_dataframe.csv"):
    if today in olddata:
        olddata.loc[(df.Date == olddata.Date), 'Total Cases'] = df.Total_Cases
        olddata.loc[(df.Date == olddata.Date), 'New Cases'] = df.New_Cases
        olddata.loc[(df.Date == olddata.Date), 'Total Deaths'] = df.Total_Deaths
        olddata.loc[(df.Date == olddata.Date), 'New Cases'] = df.New_Cases
        olddata.to_csv(r'/home/akhil/PycharmProjects/Coronavirus/export_dataframe.csv', index=False, header=True)
    else:
        combineddata = pd.concat([olddata, df], ignore_index=True)
        combineddata.to_csv(r'/home/akhil/PycharmProjects/Coronavirus/export_dataframe.csv', index=False, header=True)
else:
    # Writing Data to csv file
    df.to_csv (r'/home/akhil/PycharmProjects/Coronavirus/export_dataframe.csv', index = False, header=True)

# Plotting of Data
# create figure
fig = go.Figure()
# Add Traces
fig.add_trace(go.Bar(x=df['Country'],
                 y=df['Total Cases'],
                 name='Total Cases',
                 marker_color='rgb(77, 0, 13)'
                 ))

fig.add_trace(go.Bar(x=df['Country'],
                 y=df['New Cases'],
                 name='New Cases',
                 marker_color='rgb(255, 77, 106)'
                 ))
# Add dropdown
fig.update_layout(
    updatemenus=[
        dict(
            buttons=list([
                dict(
                    args=[{"visible": [True, False]},
                          {"title": "Total Cases"},
                          {"y-axis_type":"log"}
                           ],
                    label="Total Cases",
                    method="update"
                ),
                dict(
                    args=[{"visible": [False, True]},
                          {"title": "New Cases"}
                           ],
                    label="New Cases",
                    method="update"
                ),
                dict(
                    args=[{"visible": [True, True]},
                          {"title": "Total Cases"
                           }],
                    label="Both",
                    method="update"
                )
            ]),
            direction="down",
            pad={"r": 10, "t": 10},
            showactive=True,
            x=0.1,
            xanchor="left",
            y=1.1,
            yanchor="top"
        ),
    ]
)
fig.show()


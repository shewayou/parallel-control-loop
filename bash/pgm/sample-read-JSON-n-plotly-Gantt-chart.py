#!/usr/bin/env python
# coding: utf-8

import pandas as pd
import numpy as np
import plotly.express as px
import os
import json
import sys
'''
print( "Info: sys.executable {}".format( sys.executable  ))
print( "Info: type( sys.executable ) {}".format( type( sys.executable ) ))
print()
'''
input_file= r'../logs-n-output/runStatus-10.json'
output_html_file= r"../logs-n-output/runStatus-10-Gantt-chart.html"


folder: str= os.getcwd()
# print( "Info: os.getcwd() {}".format( folder ))
print( "Info: input JSON file {}.".format( input_file ))
print()

# Opening JSON file
f: '_io.TextIOWrapper' = open( input_file )

# returns JSON object as 
# a dictionary
json_dict: dict = json.load(f)
f.close()
'''
print( "Info: type( json.load( open('{}'))) {}".format( input_file, type( json_dict )))
print( "Info: len( json.load( open('{}')) {}".format( input_file, len( json_dict )))
print()
print( "Info: f=open('{}') type {}".format( input_file, type( f )))
print( "Info: f is closed, f.close().")
print()
'''


# print( f"Info: input file {input_file} directly load'd by json module." )
# print( f"Info: iterate on keys():")
for one_key in json_dict.keys():
    the_key= one_key
#    print( "Info: keys() {}".format( the_key ))
# print( "Info: iterate on keys() finished." )
# print()


# dataframe from { "runStatus": [ ... ] } is useless.
# data_df_entirety = pd.DataFrame.from_dict(json_dict)

# dataframe from inside, [ ... ], of { "runStatus": [ ... ] } is important!
df_json_records = pd.DataFrame.from_dict(json_dict[the_key])

'''
dataframe has these methods & attributes
df.info()
df.describe()
df.shape
df.columns
df.dtypes
df.index
'''

'''
print( "Info: DF.info()"); df_json_records.info(); print()
print( "Info: DF.describe()\n{}".format( df_json_records.describe())); print()
print( "Info: DF.shape\n{}".format( df_json_records.shape  )); print()
print( "Info: DF.columns\n{}".format( df_json_records.columns  )); print()
print( "Info: DF.dtypes\n{}".format( df_json_records.dtypes  )); print()
print( "Info: DF.index\n{}".format( df_json_records.index  )); print()
'''

'''
df_json_records['s2tartTimestamp'] = pd.to_datetime( df_json_records['startTimestamp'].str[:8], format='%Y%m%d')
df_json_records['e2ndTimestamp'] = pd.to_datetime( df_json_records['endTimestamp'].str[:8], format='%Y%m%d')
df_json_records.info()
print()
print( "Info: demo convert string to datetime")
print( df_json_records[['startTimestamp', 's2tartTimestamp', 'endTimestamp', 'e2ndTimestamp']])
'''



print( "Info: df_json_records structure B4 change:"); df_json_records.info(); print()

# Change 3 columns from object to string[python]
df_json_records=df_json_records.astype({"log": "string"
           , "startTimestamp": "string"
           , "endTimestamp": "string"} )   # "string" is correct!

# Change 2 timestamp columns from string[python] to timestamp[64]
df_json_records[[ 'startTimestamp', 'endTimestamp']] = df_json_records[['startTimestamp', 'endTimestamp']] \
    .apply( pd.to_datetime, format='%Y%m%d:%H:%M:%S.%f')

'''
# Compute wallClockDuration from endTimestamp and startTimestamp
# PS. plotly.express timeline can directly work with startTimestamp & endTimestamp. 
# No need to compute wallClockDuration.
df_json_records['wallClockDuration'] = df_json_records[ 'endTimestamp'] \
    -  df_json_records['startTimestamp'] 

print( "Info: df_json_records new column wallClockDuration from endTimestamp and startTimestamp" )
print( df_json_records[['wallClockDuration', 'startTimestamp', 'endTimestamp']])
print()
'''

'''
startTimestamp is already datetime64[ns]. Can only apply str method on string values.
AttributeError: Can only use .str accessor with string values!
df_json_records['s2tartTimestamp'] = pd.to_datetime( df_json_records['startTimestamp'].str[:8], format='%Y%m%d')
'''

'''
# PS. plotly.express timeline can directly work with startTimestamp & endTimestamp.
# No need to compute wallClockDuration.
# No need to change wallClockDuration timedelta64[ns] 'N days' value to N*24 hours for better display.
def changeTimeDeltaToTimeFormat( timedelta_column ):
    ts = timedelta_column.total_seconds()
    thousandth= int(round(   (ts-int(ts))*1000000  ))
    hours, remainder = divmod(ts, 3600)
    minutes, seconds = divmod(remainder, 60)
    return ('{}:{:02d}:{:02d}.{}').format(int(hours), int(minutes), int(seconds), thousandth ) 

df_json_records['wallClockFormat'] = df_json_records['wallClockDuration'].apply( changeTimeDeltaToTimeFormat)

# PS. plotly.express timeline can directly work with startTimestamp & endTimestamp.
print( "Info: df_json_records new column w2allClockFormat v. wallClockDuration" )
print( df_json_records[['wallClockFormat', 'wallClockDuration']])
print()
'''

'''
# Compute a new column for duration at least one hour.
df_json_records['at_least_1_hr'] = df_json_records.apply( lambda row: pd.Timedelta( hours=1 ) <= row.wallClockDuration
                , axis= 1 ) 

print( df_json_records[['startTimestamp', 'endTimestamp', 'wallClockDuration', 'at_least_1_hr']])
'''

df_json_records['imaginaryServer']= df_json_records['is'].astype( 'string' )
df_json_records['RC']= df_json_records['RC'].astype( 'string' )

df_json_records= df_json_records.drop( columns= ['is'] )
print( "Info: df_json_records structure AF change:"); df_json_records.info(); print()

'''   Show off DF sort_values method usage: by and ascending!
df_json_records= df_json_records.sort_values( by= ['imaginaryServer', 'startTimestamp']
        , ascending= [ False, False ])
'''
df_json_records= df_json_records.sort_values( by= ['imaginaryServer'] )


print( "Info: Important columns for Gantt chart:" )
print( df_json_records[['endTimestamp', 'startTimestamp', 'imaginaryServer', 'job', 'RC' ]])
print()
print( "Info: Ready for plotly.express.timeline() for Gantt chart & save to html file"); print()



fig = px.timeline(df_json_records, x_start="startTimestamp", x_end="endTimestamp", y="imaginaryServer"
                 , color= 'RC', text= 'job'
                 , title= 'Imaginary Server parallel job info. Mouseover color bars to see associated data values' )
fig.update_yaxes(autorange="reversed") # otherwise tasks are listed from the bottom up
fig.show()

fig.write_html(output_html_file)

print( "Info: look for {} file".format( output_html_file )); print( "Info: Bye!"); print()






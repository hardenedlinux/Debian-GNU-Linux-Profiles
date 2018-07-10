from bat.log_to_dataframe import LogToDataFrame
from bat import bro_log_reader
from bat.utils import vt_query
reader = bro_log_reader.BroLogReader('files.log', tail=True) # This will dynamically monitor this Bro log
for row in reader.readrows():
    pprint(vt_query.query.file(row['sha256']))

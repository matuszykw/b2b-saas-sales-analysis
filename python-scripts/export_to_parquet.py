import pandas as pd
from sqlalchemy import create_engine
import urllib
import os
import pyarrow

params = urllib.parse.quote_plus(
    "DRIVER={ODBC Driver 17 for SQL Server};"
    "SERVER=localhost;"
    "DATABASE=saas_pipeline_db;"
    "Trusted_Connection=yes;"
)
engine = create_engine(f"mssql+pyodbc:///?odbc_connect={params}")

views = ['v_OBT']

os.makedirs('../data/processed', exist_ok=True)

for view in views:
    print(f'Processing {view}')
    df = pd.read_sql(f'SELECT * FROM {view}', engine)
    df.to_parquet(f'../data/processed/{view}.parquet', index=False)
    print(f'Processed {view} - Saved {len(df)} records\n')

engine.dispose()
print('Done')
import pandas as pd
import csv
import argparse
from itertools import groupby

parser = argparse.ArgumentParser(description='A script to convert csv to lowercase!')
parser.add_argument("--a", default="ascrecomm.csv")

args = parser.parse_args()
a = args.a

df = pd.read_csv(a)
df = df.applymap(lambda x: x.lower() if pd.notnull(x) else x)
df = df.sort_values('recommendationdisplayname')
for i, g in df.groupby('recommendationdisplayname'):
    g.to_csv('{}.csv'.format(i), index=False)
    #g.to_csv('{}.csv'.format(i), header=True, index_label=False)
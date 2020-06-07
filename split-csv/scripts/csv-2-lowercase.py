import fileinput
import argparse

parser = argparse.ArgumentParser(description='A script to convert csv to lowercase!')
parser.add_argument("--a", default="1.csv", help="This is the 'a' variable")

args = parser.parse_args()
a = args.a

for line in fileinput.input(a, inplace=1):
    print(line.lower(), end='')
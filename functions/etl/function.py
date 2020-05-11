import boto3
import pandas as pd
import logging
import math
import os

logger = logging.getLogger()
logger.setLevel(logging.INFO)

console = logging.StreamHandler()
console.setLevel(logging.INFO)
# add the handler to the root logger
logging.getLogger().addHandler(console)

# Define names of columns in created CSV files
batting_columns = [
        'position',
        'name',
        'score',
        'not_out',
        'fours',
        'sixes',
        'start over',
        'end_over',
        'how_out',
        'date',
        'opposition',
        'home_away',
        'weather',
        'pitch',
        'bat_first']

bowling_columns = [
    'position',
    'name',
    'overs',
    'balls',
    'maidens',
    'runs',
    'wickets',
    '5w',
    'caught',
    'bowled',
    'caught_and_bowled',
    'lbw',
    'stumped',
    'hit_wicket',
    'date',
    'opposition',
    'home_away',
    'weather',
    'pitch']
fielding_columns = [
    'position',
    'name',
    'catches',
    'run_outs',
    'date',
    'opposition']

# Bucket to read in data from
bucket_name = os.environ['S3_BUCKET']


def check_bucket(bucket):
    s3 = boto3.resource('s3')
    bucket_exists = True
    if s3.Bucket(bucket).creation_date is None:
        bucket_exists = False
    return bucket_exists

def fix_overs(n):
    overs = math.floor(n)
    return overs

def fix_balls(n):
    overs = math.floor(n)
    balls = (n - overs) * 10
    return balls

def get_match_files(bucket):
    s3 = boto3.resource('s3')
    file_list = []
    for object in s3.Bucket(bucket).objects.all():
        if object.key.endswith('.xlsx'):
            file_list.append(object.key)
    return(file_list)


def create_averages(bucket, body, filename):
    logger.info("Writing " + filename + " to S3 Bucket " + bucket)
    s3 = boto3.client('s3')
    s3.put_object(Body=body, Bucket=bucket, Key='api/' + filename)
    return True


def parse_match(bucket, itemname):
    # Read in match file
    logger.info("Parsing match file " + itemname)
    s3 = boto3.resource('s3')
    obj = s3.Object(bucket, itemname)
    body = obj.get()['Body'].read()
    # Create Dataframes
    logger.info("Building dataframes")
    f_match_df = pd.read_excel(
        body,
        sheet_name='Sheet1',
        index=False,
        nrows=1,
        usecols='A:K')
    f_batting_df = pd.read_excel(
        body,
        sheet_name='Sheet1',
        index=False,
        skiprows=4,
        nrows=11,
        usecols='A:K')
    f_bowling_df = pd.read_excel(
        body,
        sheet_name='Sheet1',
        index=False,
        skiprows=18,
        nrows=10,
        usecols='A:L')
    f_fielding_df = pd.read_excel(
        body,
        sheet_name='Sheet1',
        index=False,
        skiprows=31,
        nrows=10,
        usecols='A:D')

    # Set the date to datetime
    f_match_df['date'] = pd.to_datetime(
        f_match_df['date'],
        infer_datetime_format=True,
        dayfirst=True)
    match_date = f_match_df['date'].iloc[0]
    home_away = f_match_df['home_away'].iloc[0]
    opposition = f_match_df['team'].iloc[0]
    weather = f_match_df['weather'].iloc[0]
    pitch = f_match_df['pitch'].iloc[0]

    # Bat first
    bat_first = 0
    if f_match_df['bat_first'].iloc[0] == 'Y':
        bat_first = 1

    # Update batting df
    f_batting_df['date'] = match_date
    f_batting_df['home_away'] = home_away
    f_batting_df['opposition'] = opposition
    f_batting_df['weather'] = weather
    f_batting_df['pitch'] = pitch
    f_batting_df['bat_first'] = bat_first
    # Add innings to all rows for easy aggregation later
    f_batting_df['innings'] = 1
    # Drop any rows where name is empty
    f_batting_df = f_batting_df[f_batting_df['name'].notna()]
    # Populate NaN values
    f_batting_df['not_out'] = f_batting_df['not_out'].apply(
        lambda x: 0 if pd.isnull(x) else x)
    f_batting_df['retired'] = f_batting_df['retired'].apply(
        lambda x: 0 if pd.isnull(x) else x)
    f_batting_df['fours'] = f_batting_df['fours'].apply(
        lambda x: 0 if pd.isnull(x) else x)
    f_batting_df['sixes'] = f_batting_df['sixes'].apply(
        lambda x: 0 if pd.isnull(x) else x)

    # Update bowling df
    f_bowling_df['date'] = match_date
    f_bowling_df['home_away'] = home_away
    f_bowling_df['opposition'] = opposition
    f_bowling_df['weather'] = weather
    f_bowling_df['pitch'] = pitch
    # Drop any rows where name is empty
    f_bowling_df = f_bowling_df[f_bowling_df['name'].notna()]
    # Populate NaN values
    for column in f_bowling_df.columns:
        f_bowling_df[column] = f_bowling_df[column].apply(
         lambda x: 0 if pd.isnull(x) else x)
    # Fix balls for incomplete overs
    f_bowling_df['balls'] = f_bowling_df['overs'].apply(fix_balls)
    f_bowling_df['overs'] = f_bowling_df['overs'].apply(fix_overs)
    f_bowling_df['5w'] = f_bowling_df['wickets'].apply(lambda x: 1 if x >= 5 else 0)

    # Update fielding df
    f_fielding_df['date'] = match_date
    f_fielding_df['opposition'] = opposition
    # Drop any rows where name is empty
    f_fielding_df = f_fielding_df[f_fielding_df['name'].notna()]
    # Populate NaN values
    for column in f_fielding_df.columns:
        f_fielding_df[column] = f_fielding_df[column].apply(
          lambda x: 0 if pd.isnull(x) else x)

    return(f_batting_df, f_bowling_df, f_fielding_df)

# Main function. Entrypoint for Lambda


def lambda_handler(event, context):
    if check_bucket(bucket_name):
        logger.info('Bucket exists - listing files')
        file_list = get_match_files(bucket_name)
        # Create overall dataframes
        batting_df = pd.DataFrame(columns=batting_columns)
        bowling_df = pd.DataFrame(columns=bowling_columns)
        fielding_df = pd.DataFrame(columns=fielding_columns)
        # Parse match files
        for item in file_list:
            df1, df2, df3 = parse_match(bucket_name, item)
            batting_df = pd.concat(
                [batting_df, df1],
                ignore_index=True)
            bowling_df = pd.concat(
                [bowling_df, df2],
                ignore_index=True)
            fielding_df = pd.concat(
                [fielding_df, df3],
                ignore_index=True)
        # Create batting averages csv
        batting_csv_body = batting_df.to_csv(index=False)
        create_averages(bucket_name, batting_csv_body, 'batting.csv')
        # Create bowling averages csv
        bowling_csv_body = bowling_df.to_csv(index=False)
        create_averages(bucket_name, bowling_csv_body, 'bowling.csv')
        # Create fielding averages csv
        fielding_csv_body = fielding_df.to_csv(index=False)
        create_averages(bucket_name, fielding_csv_body, 'fielding.csv')
        return True
    else:
        logger.error('Borked')
        return False


# Manual invocation of the script (only used for testing)
if __name__ == "__main__":
    # Test function
    lambda_handler('test', None)

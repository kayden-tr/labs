import re


env_file = '/home/khoitt/Github/labs/py/.env'

with open(env_file, 'r') as f:
    for line in f:
        if re.search("api|secret|key", line, re.IGNORECASE):
            print(line.strip())
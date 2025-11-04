import yaml

with open('/home/khoitt/Github/labs/prometheus.yml', 'r') as file:
    config = yaml.safe_load(file)
    print(config)

for k,v in config.items():
    print(f"{k.upper()}={v}") > ".env.prometheus"
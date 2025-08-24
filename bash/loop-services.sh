services=$(curl -skL https://registry.atalink.com:10443/api/v2.0/projects/bluesky/repositories?page_size=100 | jq -r '.[].name' | awk -F '/' '{print $2}')

for SERVICE in ${services[@]}; do
  echo $SERVICE
done

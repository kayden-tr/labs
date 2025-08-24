#!/bin/bash

# Chuỗi input ví dụ (bạn có thể thay đổi hoặc truyền từ tham số)
read -p "Nhập chuỗi dịch vụ (ngăn cách bằng dấu phẩy): " input
# read input="atalink_stock_report,atalink_account,reach_landed_costs,reach_atl_company_vat,reach_stock_inventory,reach_translation,atl_vidona_stock,reach_purchase_stock,reach_stock_costing,atalink_mrp,biz_atalink_webhook,atalink_ui,atalink_stock,reach_stock_report,reach_account,atlc_bmf_stock,reach_mrp,biz_atalink,atreach_stock_costing,reach_stock,reach_account_partner_reconciliation"

# Tách chuỗi thành mảng bằng dấu phẩy
IFS=',' read -r -a array <<<"$input"

# Sử dụng associative array để loại bỏ trùng lặp
declare -A unique_services

# Thêm các phần tử vào associative array
for service in "${array[@]}"; do
  unique_services[$service]=1
done

# Tạo chuỗi kết quả, nối bằng dấu phẩy không khoảng trắng
result=""
for service in "${!unique_services[@]}"; do
  if [ -z "$result" ]; then
    result="$service"
  else
    result="$result,$service"
  fi
done

# In kết quả
echo "Danh sách sau khi lọc trùng: $result"

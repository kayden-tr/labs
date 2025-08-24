#!/bin/bash

# Chuỗi input ví dụ (bạn có thể thay đổi hoặc truyền từ tham số)
read -p "Enter services split by comma: " input

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

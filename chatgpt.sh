#!/usr/bin/env bash

# ChatGPT 返回码说明:
# 0: 成功解锁
# 1: 网络连接错误
# 2: 被阻止访问
# 3: 不支持的地区
# 4: 不允许的ISP(1)
# 5: 不允许的ISP(2)
# 6: 无法解锁
# 7: 仅网页版可用(不允许的ISP[1])
# 8: 仅网页版可用(不允许的ISP[2])

# 设置变量
grep -qwE '6|-6' <<< "$1" && MODE='-6' || MODE='-4'
CURL_ARGS=$2

# ========== 1. 访问 ChatGPT 主页，检查响应 ==========
RESULT_WEB=$(curl ${CURL_ARGS} ${MODE} --user-agent "Mozilla/5.0 (Windows NT 10.0; Win64; x6*4) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/80.0.3987.87 Safari/537.36" -SsLI --max-time 10 "https://chatgpt.com" 2>&1 | grep -E 'curl:|location')

grep -q 'curl:' <<< "$RESULT_WEB" && echo -n -e "\r ChatGPT: No (Network Error).\n" && exit 1

# ========== 2. 访问 iOS 版本页面，检查限制信息 ==========
TMPRESULT_ISO=$(curl ${CURL_ARGS} ${MODE} --user-agent "Mozilla/5.0 (Windows NT 10.0; Win64; x6*4) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/80.0.3987.87 Safari/537.36" -SsL --max-time 10 "https://ios.chat.openai.com" 2>&1)

# ========== 3. 获取 CDN 信息 ==========
if grep -q '^$' <<< "$RESULT_WEB"; then
  if grep -q 'blocked_why_headline' <<< "$TMPRESULT_ISO"; then
    echo -n -e "\r ChatGPT: No (Blocked).\n" && exit 2
  elif grep -q 'unsupported_country_region_territory' <<< "$TMPRESULT_ISO"; then
    echo -n -e "\r ChatGPT: No (Unsupported Region).\n" && exit 3
  elif grep -q '(1)' <<< "$TMPRESULT_ISO"; then
    echo -n -e "\r ChatGPT: No (Disallowed ISP[1]).\n" && exit 4
  elif grep -q '(2)' <<< "$TMPRESULT_ISO"; then
    echo -n -e "\r ChatGPT: No (Disallowed ISP[2]).\n" && exit 5
  else
    echo -n -e "\r ChatGPT: No.\n" && exit 6
  fi
else
  REGION=$(curl ${CURL_ARGS} ${MODE} --user-agent "Mozilla/5.0 (Windows NT 10.0; Win64; x6*4) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/80.0.3987.87 Safari/537.36" -SsL --max-time 10 "https://chatgpt.com/cdn-cgi/trace" 2>&1 | awk -F '=' '/^loc=/{print $2}')
  if grep -q '(1)' <<< "$TMPRESULT_ISO"; then
    echo -n -e "\r ChatGPT: Web Only (Disallowed ISP[1], Region: ${REGION^^}).\n" && exit 7
  elif grep -q '(2)' <<< "$TMPRESULT_ISO"; then
    echo -n -e "\r ChatGPT: Web Only (Disallowed ISP[2], Region: ${REGION^^}).\n" && exit 8
  else
    echo -n -e "\r ChatGPT: Yes (Region: ${REGION^^}).\n" && exit 0
  fi
fi
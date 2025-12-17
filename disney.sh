#!/usr/bin/env bash

# Disney+ 返回码说明:
# 0: 成功解锁(包括日本地区)
# 1: 网络连接错误
# 2: 未知区域
# 3: 不可用
# 4: 即将支持该区域
# 5: 检测失败

# 设置变量
grep -qwE '6|-6' <<< "$1" && MODE='-6' || MODE='-4'
CURL_ARGS=$2

# Disney+ 检测函数
# ========== 1. 向Disney+设备注册接口发送请求，获取设备注册的assertion ==========
ASSERTION=$(curl --user-agent "Mozilla/5.0 (Windows NT 10.0; Win64; x6*4) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/80.0.3987.87 Safari/537.36" -s --max-time 10 -X POST "https://disney.api.edge.bamgrid.com/devices" -H "authorization: Bearer ZGlzbmV5JmJyb3dzZXImMS4wLjA.Cu56AgSfBTDag5NiRA81oLHkDZfu5L3CKadnefEAY84" -H "content-type: application/json; charset=UTF-8" -d '{"deviceFamily":"browser","applicationRuntime":"chrome","deviceProfile":"windows","attributes":{}}' 2>&1 | sed 's/.*assertion":"\([^"]\+\)".*/\1/')

grep -q 'curl:' <<< "$ASSERTION" && echo -n -e "\r Disney+: No (Network Error).\n" && exit 1

# ========== 2. 构造获取token所需的参数内容 ==========
DISNEYCOOKIE=$(sed "s/DISNEYASSERTION/${ASSERTION}/g" <<< 'grant_type=urn%3Aietf%3Aparams%3Aoauth%3Agrant-type%3Atoken-exchange&latitude=0&longitude=0&platform=browser&subject_token=DISNEYASSERTION&subject_token_type=urn%3Abamtech%3Aparams%3Aoauth%3Atoken-type%3Adevice')

# ========== 3. 使用构造好的参数向token接口发送请求，获取访问令牌 ==========
TOKEN_CONTENT=$(curl --user-agent "Mozilla/5.0 (Windows NT 10.0; Win64; x6*4) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/80.0.3987.87 Safari/537.36" -s --max-time 10 -X POST "https://disney.api.edge.bamgrid.com/token" -H "authorization: Bearer ZGlzbmV5JmJyb3dzZXImMS4wLjA.Cu56AgSfBTDag5NiRA81oLHkDZfu5L3CKadnefEAY84" -d "$DISNEYCOOKIE" 2>&1)

grep -qE 'forbidden-location|403 ERROR' <<< "$TOKEN_CONTENT" && echo -n -e "\r Disney+: No (Network Error).\n" && exit 1

# ========== 4. 从返回结果中提取refreshToken ==========
REFRESH_TOKEN=$(sed 's/.*"refresh_token":[ ]*"\([^"]\+\)".*/\1/' <<< "$TOKEN_CONTENT")

# ========== 5. 构造GraphQL查询参数 ==========
DISNEY_CONTENT='{"query":"mutation refreshToken($input: RefreshTokenInput!) {\n            refreshToken(refreshToken: $input) {\n                activeSession {\n                    sessionId\n                }\n            }\n        }","variables":{"input":{"refreshToken":"'${REFRESH_TOKEN}'"}}}'

# ========== 6. 发送GraphQL查询请求，获取用户会话及区域信息 ==========
TMP_RESULT=$(curl --user-agent "Mozilla/5.0 (Windows NT 10.0; Win64; x6*4) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/80.0.3987.87 Safari/537.36" -X POST -sSL --max-time 10 "https://disney.api.edge.bamgrid.com/graph/v1/device/graphql" -H "authorization: ZGlzbmV5JmJyb3dzZXImMS4wLjA.Cu56AgSfBTDag5NiRA81oLHkDZfu5L3CKadnefEAY84" -d "$DISNEY_CONTENT" 2>&1)

grep -q 'curl:' <<< "$TMP_RESULT" && echo -n -e "\r Disney+: No (Network Error).\n" && exit 1

# ========== 7. 访问Disney+主页，检查页面跳转情况 ==========
PREVIEW_CHECK_TMP=$(curl -s -o /dev/null -L --max-time 10 -w '%{url_effective}\n' "https://www.disneyplus.com")

grep -q 'curl:' <<< "$PREVIEW_CHECK_TMP" && echo -n -e "\r Disney+: No (Network Error).\n" && exit 1

# ========== 8. 解析返回数据，提取区域信息和可用性状态 ==========
IS_UNAVAILABLE=$(grep -E 'preview.*unavailable' <<< $PREVIEW_CHECK_TMP)

grep -q '.' <<< "$IS_UNAVAILABLE" && echo -n -e "\r Disney+: No (Unavailable).\n" && exit 3

REGION=$(sed -n 's/.*"countryCode":[ ]*"\([^"]\+\)".*/\1/p' <<< "$TMP_RESULT")

grep -q '^$' <<< "$REGION" && echo -n -e "\r Disney+: No (Unknown).\n" && exit 2

IN_SUPPORTED_LOCATION=$(sed -n 's/.*"inSupportedLocation":[ ]*\([^,]\+\),.*/\1/p' <<< "$TMP_RESULT")

grep -q 'JP' <<< "${REGION^^}" || grep -q 'true' <<< "$IN_SUPPORTED_LOCATION" && echo -n -e "\r Disney+: Yes (Region: ${REGION^^}).\n" && exit 0

grep -q 'false' <<< "$IN_SUPPORTED_LOCATION" && echo -n -e "\r Disney+: Available For [Disney+ ${REGION:-Unknown}] Soon.\n" && exit 4

echo -n -e "\r Disney+: No (Failed).\n" && exit 5
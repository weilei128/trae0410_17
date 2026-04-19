#!/bin/bash
echo '========================================'
echo '    完整功能测试 - 留言反馈系统'
echo '========================================'

BASE_URL='http://127.0.0.1:10011'
FRONTEND_URL='http://127.0.0.1:10021'

cd /opt/apps/message-board-10011
pkill -f message-board-10011.jar 2>/dev/null
sleep 2
mkdir -p data
echo '[]' > data/messages.json
nohup java -jar message-board-10011.jar --server.port=10011 > test_run.log 2>&1 &
sleep 20
echo '服务启动完成'

echo -e '\n========================================'
echo '  第一部分：基础接口测试'
echo '========================================'

echo -e '\n=== 测试1: GET /api/messages (空数据) ==='
result=$(curl -s "$BASE_URL/api/messages")
echo $result | grep -q '"total":0' && echo '✅ PASS - 空数据正确' || echo '❌ FAIL - '$result

echo -e '\n=== 测试2: POST /api/messages - 正常留言 ==='
echo '{"username":"小明", "content":"这是第一条测试留言"}' > /tmp/msg1.json
result=$(curl -s -X POST "$BASE_URL/api/messages" -H 'Content-Type: application/json' -d @/tmp/msg1.json)
echo $result | grep -q 'success' && echo '✅ PASS - 留言提交成功' || echo '❌ FAIL - '$result

echo -e '\n=== 测试3: GET /api/messages (有1条数据) ==='
result=$(curl -s "$BASE_URL/api/messages")
echo $result | grep -q '"total":1' && echo '✅ PASS - 数据总数正确' || echo '❌ FAIL - '$result

echo -e '\n=== 测试4: GET /api/messages/all ==='
result=$(curl -s "$BASE_URL/api/messages/all")
echo $result | grep -q '小明' && echo '✅ PASS - 获取全部成功' || echo '❌ FAIL - '$result

echo -e '\n========================================'
echo '  第二部分：分页功能测试'
echo '========================================'

for i in {1..15}; do
  echo "{\"username\":\"user$i\", \"content\":\"message content $i\"}" > /tmp/batch$i.json
  curl -s -X POST "$BASE_URL/api/messages" -H 'Content-Type: application/json' -d @/tmp/batch$i.json > /dev/null
done

echo -e '\n=== 测试5: 分页第1页 (默认size=10) ==='
result=$(curl -s "$BASE_URL/api/messages?page=1")
echo $result | grep -q '"page":1' && echo $result | grep -q '"total":16' && echo '✅ PASS - 第1页正确' || echo '❌ FAIL - '$result

echo -e '\n=== 测试6: 分页第2页 ==='
result=$(curl -s "$BASE_URL/api/messages?page=2")
echo $result | grep -q '"page":2' && echo '✅ PASS - 第2页正确' || echo '❌ FAIL - '$result

echo -e '\n=== 测试7: 自定义每页大小 size=5 ==='
result=$(curl -s "$BASE_URL/api/messages?page=1&size=5")
echo $result | grep -q '"size":5' && echo '✅ PASS - 自定义页大小正确' || echo '❌ FAIL'

echo -e '\n========================================'
echo '  第三部分：敏感词过滤测试'
echo '========================================'

echo -e '\n=== 测试8: 包含敏感词 ==='
echo '{"username":"badguy", "content":"这个东西很垃圾，很差劲"}' > /tmp/sen.json
result=$(curl -s -X POST "$BASE_URL/api/messages" -H 'Content-Type: application/json' -d @/tmp/sen.json)
echo $result
echo $result | grep -q '\*\*' && echo '✅ PASS - 敏感词已过滤' || echo '❌ FAIL'

echo -e '\n========================================'
echo '  第四部分：Nginx & 前端测试'
echo '========================================'

echo -e '\n=== 测试9: Nginx反向代理API ==='
result=$(curl -s "$FRONTEND_URL/api/messages")
echo $result | grep -q '"code":200' && echo '✅ PASS - Nginx代理成功' || echo '❌ FAIL'

echo -e '\n=== 测试10: 前端页面 ==='
result=$(curl -s -I "$FRONTEND_URL/" 2>&1 | head -1)
echo $result | grep -q '200' && echo '✅ PASS - 页面HTTP 200' || echo '❌ FAIL'

echo -e '\n=== 测试11: 前端HTML内容 ==='
result=$(curl -s "$FRONTEND_URL/index.html")
echo $result | grep -q '<title>' && echo '✅ PASS - HTML正常' || echo '❌ FAIL'

echo -e '\n========================================'
echo '  第五部分：数据持久化测试'
echo '========================================'

echo -e '\n=== 测试12: 服务重启数据不丢失 ==='
pkill -f message-board-10011.jar
sleep 3
nohup java -jar message-board-10011.jar --server.port=10011 > test_run2.log 2>&1 &
sleep 15
result=$(curl -s "$BASE_URL/api/messages")
echo $result | grep -q '"total":17' && echo '✅ PASS - 数据持久化成功' || echo '❌ FAIL - '$result

echo -e '\n========================================'
echo '  第六部分：公网访问测试'
echo '========================================'

echo -e '\n=== 测试13: 公网前端访问 ==='
result=$(curl -s -I 'http://49.235.161.106:10021/' --connect-timeout 5 2>&1 | head -1)
echo "结果: $result"
echo $result | grep -q '200' && echo '✅ PASS - 公网前端可访问' || echo '⚠️  请检查防火墙'

echo -e '\n=== 测试14: 公网API访问 ==='
result=$(curl -s 'http://49.235.161.106:10011/api/messages' --connect-timeout 5 2>&1)
echo $result | grep -q 'code' && echo '✅ PASS - 公网API可访问' || echo '⚠️  请检查防火墙'

echo -e '\n========================================'
echo '              测试完成'
echo '========================================'
echo -e '\n=== 最终状态 ==='
ps aux | grep message-board | grep -v grep
netstat -tlnp | grep -E '10011|10021'

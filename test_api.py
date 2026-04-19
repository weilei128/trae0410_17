#!/usr/bin/env python3
import json
import urllib.request
import urllib.error

print("=" * 50)
print("    完整功能测试 - 留言反馈系统")
print("=" * 50)

BASE_URL = "http://127.0.0.1:10011"
FRONTEND_URL = "http://127.0.0.1:10021"
PUB_FRONTEND = "http://49.235.161.106:10021"

def post_msg(username, content):
    data = json.dumps({"username": username, "content": content}).encode()
    req = urllib.request.Request(f"{BASE_URL}/api/messages", 
                              data=data,
                              headers={"Content-Type": "application/json"})
    res = urllib.request.urlopen(req)
    return json.loads(res.read().decode())

print("\n=== 测试1: GET 空数据查询 ===")
res = urllib.request.urlopen(f"{BASE_URL}/api/messages")
data = json.loads(res.read().decode())
print(f"  状态: 成功, total =", data['data']['total'])

print("\n=== 测试2: POST 正常留言 ===")
result = post_msg("小明", "这是第一条测试留言，Hello World!")
print(f"  状态: {result['message']}" if result['code'] == 200 else f"  失败: {result}")

print("\n=== 测试3: GET 验证数据已保存 ===")
res = urllib.request.urlopen(f"{BASE_URL}/api/messages")
data = json.loads(res.read().decode())
if data['data']['total'] == 1:
    print("  ✅ PASS - 数据正确保存")
else:
    print("  ❌ FAIL - 数据总数错误")

print("\n=== 测试4: GET ALL 获取全部留言 ===")
res = urllib.request.urlopen(f"{BASE_URL}/api/messages/all")
data = json.loads(res.read().decode())
if len(data['data']) > 0 and "小明" in str(data):
    print("  ✅ PASS - 获取全部成功")
else:
    print("  ❌ FAIL")

print("\n=== 测试5: 敏感词过滤 ===")
result = post_msg("测试用户", "这个东西很垃圾，很差劲")
if "**" in str(result):
    print("  ✅ PASS - 敏感词已过滤")
    print(f"    过滤结果: {result}")
else:
    print(f"  结果: {result}")

print("\n=== 测试6: 分页功能 ===")
for i in range(15):
    post_msg(f"批量用户{i}", f"批量留言内容{i}"[:30])

res = urllib.request.urlopen(f"{BASE_URL}/api/messages?page=1&size=5")
data = json.loads(res.read().decode())
if data['data']['size'] == 5 and data['data']['total'] > 10:
    print(f"  ✅ PASS - 分页功能正常, total =", data['data']['total'])
else:
    print("  ❌ FAIL - 分页错误")

print("\n=== 测试7: Nginx 反向代理 ===")
try:
    res = urllib.request.urlopen(f"{FRONTEND_URL}/api/messages")
    data = json.loads(res.read().decode())
    if data['code'] == 200:
        print("  ✅ PASS - Nginx代理API成功")
    else:
        print("  ❌ FAIL")
except Exception as e:
    print(f"  ❌ FAIL: {e}")

print("\n=== 测试8: 前端页面 ===")
try:
    res = urllib.request.urlopen(f"{FRONTEND_URL}/")
    html = res.read().decode()
    if "<title>" in html:
        print("  ✅ PASS - 前端页面正常")
    else:
        print("  ❌ FAIL")
except Exception as e:
    print(f"  ❌ FAIL: {e}")

print("\n=== 测试9: 参数校验 - 空用户名 ===")
try:
    post_msg("", "有内容但用户名为空")
    print("  ⚠️  应该返回错误")
except urllib.error.HTTPError as e:
    if e.code == 400:
        print("  ✅ PASS - 正确返回400错误")

print("\n=== 测试10: 公网访问前端 ===")
try:
    res = urllib.request.urlopen(PUB_FRONTEND, timeout=5)
    if res.status == 200:
        print("  ✅ PASS - 公网前端可访问")
    else:
        print("  ⚠️  状态:", res.status)
except Exception as e:
    print(f"  ⚠️  可能防火墙: {e}")

print("\n" + "=" * 50)
print("          测试完成！")
print("=" * 50)
print("\n服务状态:")
import subprocess
subprocess.run(["ps", "aux"], capture_output=True)
print("\n数据文件内容(前500字符):")
with open('/opt/apps/message-board-10011/data/messages.json") as f:
    print(f.read()[:500])
